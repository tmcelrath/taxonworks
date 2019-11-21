<template>
  <div>
    <div class="horizontal-left-content full_width">
      <fieldset class="full_width">
        <legend>Serial</legend>
        <smart-selector
          model="serials"
          klass="source"
          label="name"
          @selected="setSelected"/>
        <div
          class="middle separate-top"
          v-if="selected">
          <span
            class="separate-right"
            v-html="selected.name"/>
          <span
            class="button-circle btn-undo button-default separate-left"
            @click="unset"/>
        </div>
      </fieldset>
      <div class="vertical-content">
        <lock-component
          class="circle-button"
          v-model="settings.lock.serial_id"/>
        <default-pin
          section="Serials"
          type="serial"
          @getId="getDefault"/>
      </div>
    </div>
  </div>
</template>

<script>

import { GetterNames } from '../../store/getters/getters'
import { MutationNames } from '../../store/mutations/mutations'

import LockComponent from 'components/lock'
import SmartSelector from 'components/smartSelector'
import DefaultPin from 'components/getDefaultPin'

import AjaxCall from 'helpers/ajaxCall'

export default {
  components: {
    SmartSelector,
    LockComponent,
    DefaultPin
  },
  computed: {
    source: {
      get () {
        return this.$store.getters[GetterNames.GetSource]
      },
      set (value) {
        this.$store.commit(MutationNames.SetSource, value)
      }
    },
    settings: {
      get () {
        return this.$store.getters[GetterNames.GetSettings]
      },
      set (value) {
        this.$store.commit(MutationNames.SetSettings, value)
      }
    }
  },
  data () {
    return {
      selected: undefined
    }
  },
  watch: {
    source: {
      handler(newVal, oldVal) {
        if(newVal && newVal.serial_id) {
          if(!oldVal || oldVal.serial_id != newVal.serial_id) {
            AjaxCall('get', `/serials/${newVal.serial_id}`).then(response => {
              this.selected = response.body
            })
          }
        }
      },
      immediate: true
    }
  },
  methods: {
    setSelected (serial) {
      this.source.serial_id = serial.id
      this.selected = serial
    },
    unset () {
      this.selected = undefined
      this.source.serial_id = null
    },
    getDefault (id) {
      AjaxCall('get', `/serials/${id}`).then(response => {
        this.selected = response.body
      })
    }
  }
}
</script>