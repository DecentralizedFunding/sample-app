<template>
  <div class="app">
    <b-container>
      <b-img class="mt-2 mb-4" :src="`${project.image}`" width="320" height="240" blank-color="#bbb" fluid alt="Project image" />
      <b-card class="mt-4">
        <h2 class="h3">{{ project.title }}</h2>
        <p>{{ project.description }}</p>
        <b-row align-v="center">
          <b-col>
            <b-progress class="mb-1" :value="project.funded" :max="project.goal"></b-progress>
          </b-col>
          <b-col class="percent pl-0" cols="auto">{{ project.percent }}%</b-col>
        </b-row>
        <b-row class="mt-3">
          <b-col>
            <b-row class="justify-content-center text-secondary" align-v="center">
              <i class="fab fa-ethereum"></i>&nbsp;Funded
            </b-row>
            <b-row class="justify-content-center" align-v="center">
              <span class="h3">{{ project.funded }}</span>&nbsp;ETH
            </b-row>
          </b-col>
          <b-col>
            <b-row class="justify-content-center text-secondary">
              <i class="fas fa-flag-checkered"></i>&nbsp;Goal
            </b-row>
            <b-row class="justify-content-center" align-v="end">
              <span style="height: 2.5rem;">{{ project.goal }}&nbsp;ETH</span>
            </b-row>
          </b-col>
        </b-row>
        <b-row class="my-2 justify-content-center text-info">
          <i class="far fa-clock"></i>&nbsp;Time limit {{ project.date }}
        </b-row>
        <p v-show="project.supporters.length > 0">{{ project.supporters }}</p>
        <div v-show="canDeposit">
          <b-form inline>
            <b-form-input v-model="pledge" placeholder="ETH"></b-form-input>
            <b-button @click="depositInProject(project.id)" variant="primary">支援する</b-button>
          </b-form>
        </div>
      </b-card>
    </b-container>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'
import firebase from 'firebase'
import { db, storage } from '../firebaseInit'
import { sha256, sha224 } from 'js-sha256'

var DFcore = contract(artifacts)

var storageRef = storage.ref()

export default {
  name: 'Project',
  data () {
    return {
      account: null,
      project: {
        id: null,
        image: null,
        title: null,
        description: null,
        goal: 0,
        funded: 0,
        percent: 0,
        data: null,
        supporters: [],
        owner: null
      },
      // The amount of depositing by an user
      pledge: null,
      canDeposit: true
    }
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

    var contract
    DFcore.deployed()
      .then((instance) => {
        contract = instance
        return contract.getPJInfo(this.$route.params.projectId)
      })
      .then((project) => {
        var unixTime = project[4].toNumber()
        // Do not show deposit button when reach the time limit
        if (unixTime - Date.now() < 0) {
          this.canDeposit = false
        }

        this.project.id = project[0].toNumber()
        this.project.title = project[1]
        this.project.goal = Number(web3.utils.fromWei(web3.utils.toBN(project[2]), 'ether'))
        this.project.funded = Number(web3.utils.fromWei(web3.utils.toBN(project[3]), 'ether'))
        this.project.percent = Math.floor(this.project.funded / this.project.goal * 100)
        this.project.date = new Date(unixTime).toLocaleDateString('ja-JP')
        this.project.supporters = project[5]

        return contract.PJToOwner(this.project.id)
      })
      .then((owner) => {
        this.canDeposit = owner === this.account ? false : true
        this.project.owner = owner
        return db.collection('projects').doc(this.project.id.toString()).get()
      })
      .then((doc) => {
        this.project.description = doc.data().description
        return storageRef.child(`images/projects/${this.project.id}`).getDownloadURL()
      })
      .then((url) => this.project.image = url)
      .catch(console.error)

    web3.currentProvider.publicConfigStore.on('update', (info) => {
      this.account = info.selectedAddress.toLowerCase()
      this.canDeposit = this.project.owner === this.account ? false : true
    })
  },
  mounted () {
    DFcore.deployed()
      .then((instance) => {
        var deposit = instance.Deposit()
        deposit.watch((error, result) => {
          if (!error) {
            var project = result.args
            var id = project.id.toNumber()
            var funded = Number(web3.utils.fromWei(web3.utils.toBN(project.funded)))
            var pledged = Number(web3.utils.fromWei(web3.utils.toBN(project.pledged)))
            // Check whether it is a new event or not
            if (this.project.funded === funded - pledged) {
              this.project.funded = funded
            }
          }
        })
      })
  },
  methods: {
    checkAccount () {
      web3.eth.getAccounts()
        .then((accounts) => {
          // Reload the page if the user switch Metamask account
          if (this.account !== accounts[0].toLowerCase()) {
            alert('アカウントが切り替わったため、再読み込みします')
            location.reload()
          }
        })
    },
    depositInProject (id) {
      var json = [{"id":String(id),"pledge":String(web3.utils.toWei(this.pledge)),"supporter":this.account}]
      var uri = sha256(JSON.stringify(json[0]))
      return DFcore.deployed()
        .then((instance) => {
          this.checkAccount()
          return instance.deposit(id, uri, {gas: 1000000, value: web3.utils.toWei(this.pledge), from: this.account})
        }).then(() => {
          return db.collection('nftdata').doc(uri).set({
            Metadata: json
          })
        })
        .then(() => this.pledge = null)
        .catch((error) => console.error(error))
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.percent {
  font-size: 0.9rem;
  width: 68px;
}

.progress {
  height: 0.6rem;
}
</style>
