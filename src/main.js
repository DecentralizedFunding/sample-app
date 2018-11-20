// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue'
import App from './App'
import router from './router'
import firebase from 'firebase'

// require('dotenv').config()

Vue.config.productionTip = false

/* eslint-disable */

// Initialize Firebase
var config = {
  apiKey: "AIzaSyCneMwRSl1NCBrJYeJgNkqgueH7e-28qQk",
  authDomain: "decentralized-funding.firebaseapp.com",
  databaseURL: "https://decentralized-funding.firebaseio.com",
  projectId: "decentralized-funding",
  storageBucket: "decentralized-funding.appspot.com",
  messagingSenderId: "568854250007"
}
firebase.initializeApp(config)

/* eslint-disable no-new */
new Vue({
  el: '#app',
  router,
  components: { App },
  template: '<App/>'
})
