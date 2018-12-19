<template>
  <div id="app" class="container">
    <div class="top-bar container-fluid fixed-top py-2">
      <div class="top-bar_contents container d-flex align-items-center">
        <b-link :to="{ name: 'Menu' }" class="menu-button mr-2">
          <i class="fas fa-bars fa-lg"></i>
        </b-link>
        <b-link :to="{ name: 'TopPage' }" class="flex-grow-1">
          <h1 class="text-dark h2">NextFunding</h1>
        </b-link>
        <b-link v-if="!isLoggedIn" :to="{ name: 'Login' }">Log in</b-link>
        <b-link v-else :to="{ name: 'MyPage' }">
          <b-img class="profile_image" :src="`${image}`" width="36" height="36" alt="Icon" />
        </b-link>
      </div>
    </div>
    <router-view/>
  </div>
</template>

<script>
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'

import firebase from 'firebase'

export default {
  name: 'App',
  data () {
    return {
      image: null,
      isLoggedIn: false
    }
  },
  beforeCreate () {
    firebase.auth().onAuthStateChanged((user) => {
      if (user) {
        this.isLoggedIn = true
        this.image = user.photoURL
      }
    })
  }
}
</script>

<style>
.app {
  padding-top: 3rem;
}

.menu-button, .menu-button:hover {
  color: #bbb;
  margin-top: 2px;
}

.profile_image {
  border-radius: 50%;
}

.top-bar {
  background-color: #fff;
  box-shadow: 0 5px 5px -4px #bbb;
}

.top-bar a:hover {
  text-decoration: none;
}

.top-bar h1 {
  background: linear-gradient(to top, #30cfd0, #330867);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 0;
}

.top-bar_contents {
  padding-left: 0 !important;
  padding-right: 0 !important;
}

#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
  padding-bottom: 48px;
}
</style>
