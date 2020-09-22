import { GetOtu, GetOtusCoordinate } from '../../request/resources'
import { MutationNames } from '../mutations/mutations'

export default ({ commit }, id) => {
  return new Promise((resolve, reject) => {
    GetOtu(id).then(response => {
      commit(MutationNames.SetCurrentOtu, response.body)
      GetOtusCoordinate(id).then(response => {
        commit(MutationNames.SetCurrentOtu, response.body.find(otu => Number(otu.id) === Number(id)))
        commit(MutationNames.SetOtus, response.body)
        resolve(response)
      }, error => {
        reject(error)
      })
    })
  })
}
