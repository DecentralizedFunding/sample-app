import Vue from 'vue'
import Router from 'vue-router'
import Login from '@/components/Login'
import Project from '@/components/Project'
import StartProject from '@/components/StartProject'
import TopPage from '@/components/TopPage'
import User from '@/components/User'

Vue.use(Router)

export default new Router({
  mode: 'history',
  routes: [
    {
      path: '/',
      name: 'TopPage',
      component: TopPage
    },
    {
      path: '/project/:projectId',
      name: 'Project',
      component: Project
    },
    {
      path: '/create',
      name: 'StartProject',
      component: StartProject
    },
    {
      path: '/login',
      name: 'Login',
      component: Login
    },
    {
      path: '/user/:userId',
      name: 'User',
      component: User
    }
  ]
})
