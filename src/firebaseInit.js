import firebase from 'firebase'
import 'firebase/firestore'
import firebaseConfig from './firebaseConfig'

var firebaseApp = firebase.initializeApp(firebaseConfig)
var firestore = firebaseApp.firestore()

var settings = {timestampsInSnapshots: true}
firestore.settings(settings)

export default firestore
