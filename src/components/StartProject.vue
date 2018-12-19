<template>
  <div class="app">
    <b-card class="mt-4">
      <h2 class="h3">Start a Project</h2>
      <b-form @submit="onSubmit">
        <b-form-group label="Image">
          <b-form-file v-model="form.imageFile" accept=".jpg, .png" placeholder="JPG or PNG" required></b-form-file>
        </b-form-group>
        <b-form-group label="Title">
          <b-form-input v-model="form.title" type="text" placeholder="Purpose" required></b-form-input>
        </b-form-group>
        <b-form-group label="What do you want to do?">
          <b-form-textarea v-model="form.content" type="text" placeholder="Description" :rows="2" :max-rows="6" required></b-form-textarea>
        </b-form-group>
        <b-form-group label="Goal">
          <b-input-group append="ETH">
            <b-form-input v-model="form.goal" type="text" placeholder="0.1" required></b-form-input>
          </b-input-group>
        </b-form-group>
        <b-form-group label="Time limit">
          <b-form-input v-model="form.date" type="date" :state="validateDate" required></b-form-input>
          <b-form-invalid-feedback>Invalid date.</b-form-invalid-feedback>
        </b-form-group>
        <b-row class="my-2 justify-content-center" v-show="isLoading">
          <atom-spinner :animation-duration="1000" :size="60" :color="'#007bff'" />
        </b-row>
        <b-alert class="my-2" v-show="errorMessage" show variant="danger">{{ errorMessage }}</b-alert>
        <b-button class="w-100 mt-2" v-if="isFormFilled" @click="startProject" type="submit" variant="primary">Start</b-button>
        <b-button class="w-100 mt-2" v-else variant="secondary" disabled>Start</b-button>
      </b-form>
    </b-card>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'

var DFcore = contract(artifacts)

import firebase from 'firebase'
import { db, storage } from '../firebaseInit'

import { AtomSpinner } from 'epic-spinners'

var storageRef = storage.ref()

export default {
  name: 'CreateProject',
  data () {
    return {
      account: null,
      uid: null,
      form: {
        imageFile: null,
        title: null,
        content: null,
        goal: null,
        date: null
      },
      errorMessage: null,
      isLoading: false
    }
  },
  components: {
    AtomSpinner
  },
  computed: {
    isFormFilled () {
      return (this.form.imageFile !== null && this.form.title !== null && this.form.content !== null && this.form.goal !== null && this.form.date !== null) ? true : false
    },
    isNumber () {
      console.log(typeof this.form.goal);
      return typeof this.form.goal === 'number' ? true : false
    },
    validateDate () {
      return this.form.date === null ? null : Date.now() < new Date(this.form.date) ? true : false
    }
  },
  beforeCreate () {
    firebase.auth().onAuthStateChanged((user) => {
      if (!user) {
        this.$router.replace({ name: 'Login' })
      }
    })
  },
  created () {
    if (typeof web3 !== 'undefined') {
      web3 = new Web3(web3.currentProvider)
    } else {
      console.warn("No web3 detected. Falling back to http://127.0.0.1:7545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask")

      // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
      web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'))
    }

    DFcore.setProvider(web3.currentProvider)

    web3.eth.getCoinbase()
      .then((coinbase) => DFcore.defaults({from: coinbase}))

    web3.eth.getAccounts()
      .then((accounts) => this.account = accounts[0].toLowerCase())
      .catch(console.error)

    web3.currentProvider.publicConfigStore.on('update', (info) => {
      this.account = info.selectedAddress.toLowerCase()
    })
  },
  /*
  updated () {
    var reader = new FileReader()
    reader.onload = (e) => {
      this.previewImage = e.target.result
    }
    reader.readAsDataURL(this.imageFile)
  },*/
  /*
  mounted () {
    DFcore.deployed()
      .then((instance) => {
        var createdProject = instance.NewPJ()
        createdProject.watch((error, result) => {
          if (!error && this.form.title !== null) {
            // Move to the project page after creating it
            var id = result.args.id.toNumber()
            this.$router.replace({ name: 'Project', params: { projectId: id }})
          }
        })
      })
  },*/
  methods: {
    onSubmit (event) {
      event.preventDefault()
    },
    checkAccount () {
      web3.eth.getAccounts()
        .then((accounts) => {
        // Reload the page if the user switch Metamask account
        if (this.account !== accounts[0].toLowerCase()) {
          alert('Reload this page because of switching Metamask account')
          location.reload()
        }
      })
    },
    startProject () {
      this.isLoading = true

      var limit = new Date(this.form.date)
      var contract
      var projectId
      var uid

      this.checkAccount()

      new Promise((resolve, reject) => {
        firebase.auth().onAuthStateChanged((user) => {
          if (!user) {
            this.$router.replace({ name: 'Login' })
          } else {
            resolve(user.uid)
          }
        })
      })
      .then((result) => {
        uid = result
        return DFcore.deployed()
      })
      .then((instance) => {
        contract = instance
        return db.collection('users').doc(uid).get()
      }).then((doc) => {
        // get registered address from firestore
        var registerdAddress = doc.data().address
        // If using wallet is not registered, throw error
        if (this.account !== registerdAddress.toLowerCase()) {
          throw new Error('app/address-not-registered')
        }

        return contract.makePJ(this.form.title, web3.utils.toWei(this.form.goal, 'ether'), limit.getTime() / 1000)
      })
      .then(() => {
        return contract.getPJCount()
      })
      .then((count) => {
        projectId = count.toNumber() - 1
        /*
        var extension
        switch (this.image.type) {
          case 'image/jpeg':
            extension = 'jpg'
            break
          case 'image/png':
            extension = 'png'
            break
          default:
            throw new Error('This type of image is not adapted')
        }*/
        var newImageRef = storageRef.child(`images/projects/${projectId}`)
        return newImageRef.put(this.form.imageFile)
      })
      .then(() => {
        return db.collection('projects').doc(projectId.toString())
          .set({description: this.form.content})
      })
      .then(() => {
        this.isLoading = false
        this.$router.replace({ name: 'Project', params: { projectId: projectId }})
      })
      .catch((error) => {
        this.isLoading = false
        switch (error.message) {
          case 'app/address-not-registered':
            this.errorMessage = 'Connected wallet address is not registered.'
            break
          default:
            console.error(error)
        }
      })
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
