/* eslint-disable */

import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

import Web3 from 'web3'
import contract from 'truffle-contract'
import artifacts from '../../build/contracts/DFcore.json'

var DFcore = contract(artifacts)

export default new Vuex.Store({
  state: {
    web3 : {
      instance: null,
      coinbase: null
    },
    contractInstance: null
  },
  mutations: {
    registerWeb3Instance (state, payload) {
      state.web3.instance = payload.web3
      state.web3.coinbase = payload.coinbase
    },
    registerContract (state, payload) {
      state.contractInstance = payload
    }
  },
  actions: {
    register ({commit}) {
      new Promise((resolve, reject) => {
        if (typeof web3 !== 'undefined') {
          web3 = new Web3(web3.currentProvider)
        } else {
          console.warn("No web3 detected. Falling back to http://127.0.0.1:7545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask")

          // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
          web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:7545'))
        }
        resolve({
          web3 () {
            return web3
          }
        })
      })
      .then((result) => {
        return new Promise((resolve, reject) => {
          result.web3().eth.getCoinbase((error, coinbase) => {
            if (!error) {
              result = Object.assign({}, result, { coinbase })
              resolve(result)
            }
          })
        })
      })
      .then((result) => {
        // Register web3
        commit('registerWeb3Instance', result)
        // Set provider
        DFcore.setProvider(result.web3().currentProvider)
        return DFcore.deployed()
      })
      .then((instance) => commit('registerContract', instance))
      .catch((error) => console.error)
    }
  }
})
