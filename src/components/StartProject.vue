<template>
  <div class="app">
    <h2>Create Project</h2>
    <b-form class="mx-auto" style="width: 320px;" @submit="onSubmit">
      <b-form-group label="アイキャッチ画像">
        <b-form-file v-model="form.image" accept=".jpg, .png" placeholder="JPG または PNG" required></b-form-file>
      </b-form-group>
      <b-form-group label="タイトル">
        <b-form-input v-model="form.title" type="text" placeholder="タイトル (目的)" required></b-form-input>
      </b-form-group>
      <b-form-group label="やりたいこと">
        <b-form-input v-model="form.content" type="text" placeholder="説明文" required></b-form-input>
      </b-form-group>
      <b-form-group label="目標金額">
        <b-form-input v-model="form.goal" type="text" placeholder="ETH" required></b-form-input>
      </b-form-group>
      <b-form-group label="期限">
        <b-form-input v-model="form.date" type="date" required></b-form-input>
      </b-form-group>
      <b-button v-if="isFormFilled" @click="startProject" type="submit" variant="primary">つくる</b-button>
      <b-button v-else variant="secondary" disabled>つくる</b-button>
      <b-alert v-if="errorMessage" show variant="danger">{{ errorMessage }}</b-alert>
    </b-form>
    <router-link :to="{ name: 'TopPage' }">← トップに戻る</router-link>
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

var storageRef = storage.ref()

export default {
  name: 'CreateProject',
  data () {
    return {
      account: null,
      uid: null,
      form: {
        image: null,
        title: null,
        content: null,
        goal: null,
        date: null
      },
      errorMessage: null
    }
  },
  computed: {
    isFormFilled () {
      if (this.form.image !== null && this.form.title !== null && this.form.content !== null && this.form.goal !== null && this.form.date !== null) {
        return true
      } else {
        return false
      }
    }
  },
  beforeCreate () {
    firebase.auth().onAuthStateChanged((user) => {
      if (!user) {
        this.$router.replace({ name: 'SignUp' })
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
      .then((accounts) => this.account = accounts[0])
      .catch(console.error)

    web3.currentProvider.publicConfigStore.on('update', (info) => this.account = info.selectedAddress)

    DFcore.deployed()
      .then((instance) => this.contractAddress = instance.address)
  },
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
  },
  methods: {
    onSubmit (event) {
      event.preventDefault()
    },
    checkAccount () {
      web3.eth.getAccounts()
        .then((accounts) => {
        // Reload the page if the user switch Metamask account
        if (this.account !== accounts[0]) {
          alert('アカウントが切り替わったため、再読み込みします')
          location.reload()
        }
      })
    },
    startProject () {
      var limit = new Date(this.form.date)
      var contract
      var projectId
      var uid

      firebase.auth().onAuthStateChanged((user) => {
        if (!user) {
          this.$router.replace({ name: 'SignUp' })
        } else {
          uid = user.uid
        }
      })

      this.checkAccount()

      DFcore.deployed()
        .then((instance) => {
          contract = instance
          return db.collection('users').doc(uid).get()
        }).then((doc) => {
          // get registered address from firestore
          var registerdAddress = doc.data().address
          // If using wallet is not registered, throw error
          if (this.account !== registerdAddress) {
            this.errorMessage = '登録したウォレットを使用してください'
            throw new Error('Connected wallet address is not registered.')
          }

          return contract.makePJ(this.form.title, web3.utils.toWei(this.form.goal, 'ether'), limit.getTime())
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
          return newImageRef.put(this.form.image)
        })
        .then(() => {
          return db.collection('projects').doc(projectId.toString())
            .set({description: this.form.content})
        })
        .catch((error) => console.error(error))
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
