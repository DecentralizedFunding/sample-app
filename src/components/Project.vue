<template>
  <div class="app">
    <h2>Project page</h2>
    <h3>{{ title }}</h3>
    <p>目標金額 {{ goal }} ETH</p>
    <p>集まった金額 {{ funded }} ETH</p>
    <p>支援期限 {{ date }}</p>
    <p>{{ supporters }}</p>
    <div v-if="canDeposit">
      <input v-model="pledge" placeholder="ETH"><button @click="depositInProject(id)">支援する</button>
    </div>
    <div v-if="!canDeposit&(goal<funded)">
      <b-button>引き出す</b-button>
    </div>
    <router-link :to="{ name: 'TopPage' }">← トップに戻る</router-link>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'
import firebase from 'firebase'
import db from '../firebaseInit'
import { sha256, sha224 } from 'js-sha256'

var DFcore = contract(artifacts)

export default {
  name: 'Project',
  data () {
    return {
      account: null,
      id: null,
      title: null,
      goal: null,
      funded: null,
      date: null,
      supporters: [],
      owner: null,
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
      .then((accounts) => this.account = accounts[0])
      .catch(console.log)

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

        this.id = project[0].toNumber()
        this.title = project[1]
        this.goal = web3.utils.fromWei(web3.utils.toBN(project[2]))
        this.funded = web3.utils.fromWei(web3.utils.toBN(project[3]))
        this.date = new Date(unixTime).toLocaleDateString('ja-JP')
        this.supporters = project[5]

        return contract.PJToOwner(this.id)
      })
      .then((owner) => this.owner = owner)

    web3.currentProvider.publicConfigStore.on('update', (info) => {
      this.account = info.selectedAddress
      if (this.owner === this.account.toLowerCase()) {
        this.canDeposit = false
      } else {
        this.canDeposit = true
      }
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
            var funded = web3.utils.fromWei(web3.utils.toBN(project.funded))
            var pledged = web3.utils.fromWei(web3.utils.toBN(project.pledged))
            // Check whether it is a new event or not
            if (Number(this.funded) === Number(funded) - Number(pledged)) {
              this.funded = funded
              this.supporters = project.supporters
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
          if (this.account !== accounts[0]) {
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
          return instance.deposit(id, uri, {gas: 1000000, value: web3.utils.toWei(this.pledge)})
        }).then(() => {
          return db.collection('nftdata').doc(uri).set({
            Metadata: json
          })
        })
        .then(() => this.pledge = null)
        .catch((error) => console.error(error))
    },
    success_withdraw (id) {
      return DFcore.deployed()
        .then((instancd) => {
          this
        })
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
