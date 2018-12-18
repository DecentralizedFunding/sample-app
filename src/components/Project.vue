<template>
  <div class="app">
    <b-container class="alert-error">
      <transition name="slide-in-from-top">
        <b-alert class="mt-3" :show="errorMessage !== null" variant="danger">{{ errorMessage }}</b-alert>
      </transition>
    </b-container>
    <b-img class="top-image mt-2" :src="`${project.image}`" alt="Project image" />
    <div class="sns-bar px-4">
      <b-row class="pb-4" align-v="end">
        <b-col class="pr-0" cols="auto">
          <b-img class="owner-icon" width="48" height="48" :src="`${project.ownerImage}`" alt="Owner image" />
        </b-col>
        <b-col class="h5">
          <b-link style="color: #ddd;" :to="{ name: 'User', params: { address: project.owner }}">
            @{{ project.ownerName }}
          </b-link>
        </b-col>
      </b-row>
    </div>
    <b-container class="pb-5">
      <b-card>
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
            <b-row class="info-tag justify-content-center text-secondary" align-v="center">
              <i class="fab fa-ethereum"></i>&nbsp;Funded
            </b-row>
            <b-row class="justify-content-center" align-v="center">
              <span class="h3">{{ project.funded }}</span>&nbsp;ETH
            </b-row>
          </b-col>
          <b-col>
            <b-row class="info-tag justify-content-center text-secondary" align-v="center">
              <i class="fas fa-flag-checkered"></i>&nbsp;Goal
            </b-row>
            <b-row class="justify-content-center" align-v="end">
              <span style="margin-top: 0.4rem;">{{ project.goal }}&nbsp;ETH</span>
            </b-row>
          </b-col>
        </b-row>
        <b-row class="my-2 justify-content-center text-info font-weight-bold" align-v="center">
          <i class="far fa-clock"></i>&nbsp;Time limit {{ project.date }}
        </b-row>
        <b-col>
          <b-row class="mt-4 ml-1 mb-1 text-secondary" align-v="center">
            <span class="info-tag mr-2"><i class="fas fa-users"></i>&nbsp;Supporters</span>{{ project.supporters.length }}
          </b-row>
        </b-col>
        <b-list-group class="mb-4 address-list" flush>
          <b-list-group-item class="text-info" :to="{ name: 'User', params: { address: supporter }}" v-for="supporter in project.supporters">
            {{ supporter }}
          </b-list-group-item>
        </b-list-group>
        <div v-show="canDeposit">
          <b-form inline>
            <b-form-input v-model="pledge" placeholder="ETH"></b-form-input>
            <b-button @click="depositInProject(project.id)" variant="primary">支援する</b-button>
          </b-form>
        </div>
      </b-card>
    </b-container>
    <b-row class="fixed-bottom justify-content-center mb-3" v-show="canDeposit">
      <b-button v-b-toggle.collapse1 variant="primary">Support</b-button>
      <b-collapse id="collapse1" class="mt-2">
        <b-card>
          content
        </b-card>
      </b-collapse>
    </b-row>
    <transition name="slide-in-from-top">
      <div v-show="openDepositForm" class="depositForm">

      </div>
    </transition>
  </div>
</template>

<script>
/* eslint-disable */
import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'
import firebase from 'firebase'
import { db, storage } from '../firebaseInit'
import { sha256 } from 'js-sha256'

var DFcore = contract(artifacts)

var storageRef = storage.ref()

export default {
  name: 'Project',
  data () {
    return {
      account: null,
      errorMessage: null,
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
        owner: null,
        ownerImage: null,
        ownerName: null
      },
      openDepositForm: false,
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
      .then((url) => {
        this.project.image = url
        return db.collection('users').where('lowerCaseAddress', '==', this.project.owner).get()
      })
      .then((querySnapshot) => {
        querySnapshot.forEach((doc) => {
          this.project.ownerName = doc.data().name
        })
        return storageRef.child(`images/users/${this.project.ownerName}`).getDownloadURL()
      })
      .then((url) => this.project.ownerImage = url)
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
              this.project.supporters = project.supporters
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
            alert('Reload this page because of switching Metamask account')
            location.reload()
          }
        })
    },
    depositInProject (id) {
      var user
      try {
        if (this.project.owner === this.account) {
          throw new Error('Same to owner\'s')
        }
      } catch (error) {
        switch (error.message) {
          case 'Same to owner\'s':
            this.showError('This address is same to owner\'s.')
            break
          default:
            console.log(error)
        }
      }

      var json = [{"id":String(id),"pledge":String(web3.utils.toWei(this.pledge)),"supporter":this.account}]
      var uri = sha256(JSON.stringify(json[0]))
      new Promise((resolve, reject) => {
        firebase.auth().onAuthStateChanged((res) => {
          user = res
          if (!user) {
            reject(new Error('Need to log in'))
            return
          }
        })
      })
      .then(() => {
        return DFcore.deployed()
      })
        .then((instance) => {
          this.checkAccount()
          return db.collection('users').doc(user.uid).get()
        })
        .then((doc) => {
          // Check whether wallet address is registered or not
          if (doc.data().lowerCaseAddress !== this.account) {
            throw new Error('Not registered')
          }
          return instance.deposit(id, uri, {gas: 1000000, value: web3.utils.toWei(this.pledge), from: this.account})
        }).then(() => {
          return db.collection('nftdata').doc(uri).set({
            Metadata: json
          })
        })
        .then(() => this.pledge = null)
        .catch((error) => {
          switch (error.message) {
            case 'Not registered':
              this.showError('Use registered wallet.')
              break
            case 'Need to log in':
              this.showError('You need to log in if you want to support this project.')
              break
            default:
              console.error(error)
          }
        })
    },
    showError (message) {
      this.errorMessage = message
      setTimeout(() => {
        this.errorMessage = null
      }, 3000)
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.address-list a {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.alert-error {
  left: 0;
  position: fixed;
  z-index: 2000;
}

.depositForm {
  position: fixed;
  z-index: 2000;
}

.info-tag {
  font-size: 0.8rem;
}

.owner-icon {
  border-radius: 50%;
}

.percent {
  font-size: 0.9rem;
  width: 68px;
}

.progress {
  height: 0.6rem;
}

.slide-in-from-top-enter-active {
  transition: all .3s ease;
}

.slide-in-from-top-leave-active {
  transition: all .3s ease;
}

.slide-in-from-top-enter, .slide-in-from-top-leave-to
/* .slide-fade-leave-active below version 2.1.8 */ {
  transform: translateY(-100px);
  opacity: 0;
}

.sns-bar {
  background: linear-gradient(transparent, rgba(0, 0, 0, 0.8));
  height: 64px;
  margin-bottom: -48px;
  margin-left: -15px;
  margin-right: -15px;
  position: relative;
  top: -64px;
}

.top-image {
  margin-left: -15px;
  width: calc(100% + 30px);
}
</style>
