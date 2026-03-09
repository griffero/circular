import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/components/pages/LoginPage.vue'),
    },
    {
      path: '/auth/verify',
      name: 'auth-verify',
      component: () => import('@/components/pages/AuthVerifyPage.vue'),
    },
    // Settings routes with dedicated layout (like Linear)
    {
      path: '/settings',
      component: () => import('@/components/pages/SettingsLayout.vue'),
      children: [
        {
          path: '',
          name: 'general-settings',
          component: () => import('@/components/pages/settings/GeneralSettings.vue'),
        },
        {
          path: 'preferences',
          name: 'preferences-settings',
          component: () => import('@/components/pages/settings/PreferencesSettings.vue'),
        },
        {
          path: 'profile',
          name: 'profile-settings',
          component: () => import('@/components/pages/settings/ProfileSettings.vue'),
        },
        {
          path: 'members',
          name: 'members-settings',
          component: () => import('@/components/pages/settings/MembersSettings.vue'),
        },
        {
          path: 'teams',
          name: 'teams-settings',
          component: () => import('@/components/pages/settings/TeamsSettings.vue'),
        },
        {
          path: 'labels',
          name: 'labels-settings',
          component: () => import('@/components/pages/settings/LabelsSettings.vue'),
        },
      ],
    },
    {
      path: '/',
      name: 'app',
      component: () => import('@/components/pages/AppLayout.vue'),
      children: [
        {
          path: '',
          name: 'home',
          component: () => import('@/components/pages/HomePage.vue'),
        },
        {
          path: 'inbox',
          name: 'inbox',
          component: () => import('@/components/pages/InboxPage.vue'),
        },
        {
          path: 'my-issues',
          name: 'my-issues',
          component: () => import('@/components/pages/MyIssuesPage.vue'),
        },
        {
          path: 'initiatives',
          name: 'initiatives',
          component: () => import('@/components/pages/InitiativesPage.vue'),
        },
        {
          path: 'projects',
          name: 'projects',
          component: () => import('@/components/pages/ProjectsPage.vue'),
        },
        {
          path: 'views',
          name: 'views',
          component: () => import('@/components/pages/ViewsPage.vue'),
        },
        {
          path: 'team/:teamKey',
          name: 'team',
          component: () => import('@/components/pages/TeamPage.vue'),
          redirect: to => `/team/${to.params.teamKey}/issues`,
          children: [
            {
              path: 'triage',
              name: 'team-triage',
              component: () => import('@/components/pages/team/TeamTriagePage.vue'),
            },
            {
              path: 'issues',
              name: 'team-issues',
              component: () => import('@/components/pages/team/TeamIssuesPage.vue'),
            },
            {
              path: 'active',
              name: 'team-active',
              component: () => import('@/components/pages/team/TeamActivePage.vue'),
            },
            {
              path: 'backlog',
              name: 'team-backlog',
              component: () => import('@/components/pages/team/TeamBacklogPage.vue'),
            },
            {
              path: 'board',
              name: 'team-board',
              component: () => import('@/components/pages/team/TeamBoardPage.vue'),
            },
            {
              path: 'cycles',
              name: 'team-cycles',
              component: () => import('@/components/pages/team/TeamCyclesPage.vue'),
            },
            {
              path: 'cycles/current',
              name: 'team-cycles-current',
              component: () => import('@/components/pages/team/TeamCyclesPage.vue'),
            },
            {
              path: 'cycles/upcoming',
              name: 'team-cycles-upcoming',
              component: () => import('@/components/pages/team/TeamCyclesPage.vue'),
            },
            {
              path: 'projects',
              name: 'team-projects',
              component: () => import('@/components/pages/team/TeamProjectsPage.vue'),
            },
            {
              path: 'views',
              name: 'team-views',
              component: () => import('@/components/pages/team/TeamViewsPage.vue'),
            },
          ],
        },
        {
          path: 'project/:projectSlug',
          name: 'project',
          component: () => import('@/components/pages/ProjectPage.vue'),
        },
        {
          path: 'issue/:issueId',
          name: 'issue',
          component: () => import('@/components/pages/IssuePage.vue'),
        },
        {
          path: 'view/:viewId',
          name: 'view',
          component: () => import('@/components/pages/ViewPage.vue'),
        },
        {
          path: 'profile/:userId',
          name: 'user-profile',
          component: () => import('@/components/pages/UserProfilePage.vue'),
        },
      ],
    },
  ],
})

// Navigation guard
router.beforeEach(async (to) => {
  const authStore = useAuthStore()
  
  // Initialize auth state if not already done
  if (!authStore.initialized) {
    await authStore.fetchCurrentUser()
  }
  
  const isAuthenticated = authStore.isAuthenticated
  const isAuthPage = to.name === 'login' || to.name === 'auth-verify'
  
  // Redirect authenticated users away from login/auth pages
  if (isAuthenticated && isAuthPage) {
    return { name: 'home' }
  }
  
  // Allow auth pages without authentication
  if (isAuthPage) {
    return true
  }
  
  // Redirect unauthenticated users to login
  if (!isAuthenticated) {
    return { name: 'login' }
  }
  
  return true
})

export default router
