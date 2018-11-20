<template>
  <div class="app">
    <h2>Create Project</h2>
    <input v-model="title" type="text" name="" value="" placeholder="プロジェクトの目的" required>
    <input v-model="goal" type="text" name="" value="" placeholder="目標金額 (ETH)" required>
    <input v-model="date" type="date" name="" value="" required>
    <button @click="startProject">つくる</button>
    <router-link :to="{ name: 'TopPage' }">← トップに戻る</router-link>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'

var DFcore = contract(artifacts)

export default {
  name: 'CreateProject',
  data () {
    return {
      title: null,
      goal: null,
      date: null
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

    web3.currentProvider.publicConfigStore.on('update', (info) => this.account = info.selectedAddress)

    DFcore.deployed()
      .then((instance) => this.contractAddress = instance.address)
  },
  mounted () {
    DFcore.deployed()
      .then((instance) => {
        var createdProject = instance.NewPJ()
        createdProject.watch((error, result) => {
          if (!error && this.title !== null) {
            // Move to the project page after creating it
            var id = result.args.id.toNumber()
            this.$router.replace({ name: 'Project', params: { projectId: id }})
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
    startProject () {
      var limit = new Date(this.date)
      return DFcore.deployed()
        .then((instance) => {
          this.checkAccount()
          return instance.makePJ(this.title, web3.utils.toWei(this.goal, 'ether'), limit.getTime())
        })
        .catch((error) => console.error(error))
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

</style>
