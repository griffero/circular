# frozen_string_literal: true

module Api
  module V1
    class CommentsController < BaseController
      before_action :set_issue
      before_action :set_comment, only: %i[show update destroy]

      def index
        comments = @issue.comments.includes(:user, replies: :user).top_level.ordered

        render json: {
          comments: CommentSerializer.render_as_hash(comments, view: :detailed)
        }
      end

      def show
        authorize @comment
        render json: {
          comment: CommentSerializer.render_as_hash(@comment, view: :detailed)
        }
      end

      def create
        comment = @issue.comments.new(comment_params)
        comment.user = current_user
        authorize comment

        if comment.save
          broadcast_comment_created(comment)

          render json: {
            comment: CommentSerializer.render_as_hash(comment, view: :with_user)
          }, status: :created
        else
          render json: { error: comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize @comment

        if @comment.update(body: params[:comment][:body], edited_at: Time.current)
          broadcast_comment_updated(@comment)

          render json: {
            comment: CommentSerializer.render_as_hash(@comment, view: :with_user)
          }
        else
          render json: { error: @comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @comment
        @comment.destroy!
        broadcast_comment_deleted(@comment)
        head :no_content
      end

      private

      def set_issue
        @issue = Issue.find(params[:issue_id])
      end

      def set_comment
        @comment = @issue.comments.find(params[:id])
      end

      def comment_params
        params.require(:comment).permit(:body, :body_html, :parent_id)
      end

      # Realtime broadcasts
      def broadcast_comment_created(comment)
        ActionCable.server.broadcast(
          "issue_#{@issue.id}",
          { type: "comment.created", comment: CommentSerializer.render_as_hash(comment, view: :with_user) }
        )
      end

      def broadcast_comment_updated(comment)
        ActionCable.server.broadcast(
          "issue_#{@issue.id}",
          { type: "comment.updated", comment: CommentSerializer.render_as_hash(comment, view: :with_user) }
        )
      end

      def broadcast_comment_deleted(comment)
        ActionCable.server.broadcast(
          "issue_#{@issue.id}",
          { type: "comment.deleted", comment_id: comment.id }
        )
      end
    end
  end
end
