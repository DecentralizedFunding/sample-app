import Vue from 'vue'
import Router from 'vue-router'
import BootstrapVue from 'bootstrap-vue'

import Login from '@/components/Login'
import Project from '@/components/Project'
import SignUp from '@/components/SignUp'
import StartProject from '@/components/StartProject'
import TopPage from '@/components/TopPage'
import User from '@/components/User'

Vue.use(Router)
Vue.use(BootstrapVue)

export default new Router({
  mode: 'history',
  routes: [
    {
      path: '/login',
      name: 'Login',
      component: Login
    },
    {
      path: '/project/:projectId',
      name: 'Project',
      component: Project
    },
    {
      path: '/signup',
      name: 'SignUp',
      component: SignUp
    },
    {
      path: '/create',
      name: 'StartProject',
      component: StartProject
    },
    {
      path: '/',
      name: 'TopPage',
      component: TopPage
    },
    {
      path: '/user/:address',
      name: 'User',
      component: User
    }
  ]
})
