<template>
  <div>
    <button
      class="button normal-input button-default"
      @click="openModal">Enter coordinates</button>
    <modal-component
      v-if="show"
      @close="show = false">
      <h3 slot="header">Create georeference</h3>
      <div slot="body">
        <div class="field">
          <label>Latitude</label>
          <input
            type="text"
            v-model="shape.lat">
        </div>
        <div class="field">
          <label>Longitude</label>
          <input 
            type="text"
            v-model="shape.long">
        </div>
        <div class="field">
          <label>Range distance</label>
          <label
            v-for="range in ranges"
            :key="range">
            <input
              type="radio"
              name="georeference-distance"
              :value="range"
              v-model="shape.range">
              {{ range }}
          </label>
        </div>
      </div>
      <div slot="footer">
        <button
          type="button"
          class="normal-input button button-submit"
          :disabled="!validateFields"
          @click="createShape">
          Add point
        </button>
      </div>
    </modal-component>
  </div>
</template>

<script>

import ModalComponent from 'components/modal'
import convertDMS from 'helpers/parseDMS.js'

export default {
  components: {
    ModalComponent
  },
  computed: {
    validateFields () {
      return convertDMS(this.shape.lat) && convertDMS(this.shape.long)
    }
  },
  data () {
    return {
      show: false,
      ranges: [0, 10, 100, 1000, 10000],
      shape: this.resetShape()
    }
  },
  methods: {
    createShape () {
      this.$emit('create', {
        type: 'Feature',
        properties: this.shape.range > 0 ? { radius: this.shape.range } : {},
        geometry: {
          type: 'Point',
          coordinates: [convertDMS(this.shape.long), convertDMS(this.shape.lat)]
        }
      })
      this.shape = this.resetShape()
      this.show = false
    },
    resetShape () {
      return {
        lat: undefined,
        long: undefined,
        range: 0
      }
    },
    openModal () {
      this.show = true
      this.shape = this.resetShape()
    }
  }
}
</script>

<style lang="scss" scoped>
  /deep/ .modal-container {
    max-width: 300px;
  }
</style>