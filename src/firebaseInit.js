import firebase from 'firebase'
import 'firebase/firestore'
import firebaseConfig from './firebaseConfig'

var firebaseApp = firebase.initializeApp(firebaseConfig)
var db = firebaseApp.firestore()
var storage = firebaseApp.storage()

var settings = {timestampsInSnapshots: true}
db.settings(settings)

export {
  db, storage
}
