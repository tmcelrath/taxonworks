<template>
  <div>
    <h2>Validity</h2>
    <ul class="no_bullets">
      <li
        v-for="option in options">
        <label>
          <input
            :value="option.value"
            v-model="optionValue"
            type="radio">
          {{ option.label }}
        </label>
      </li>
    </ul>
  </div>
</template>

<script>

import { URLParamsToJSON } from 'helpers/url/parse.js'

export default {
  props: {
    value: {
      default: undefined
    }
  },
  computed: {
    optionValue: {
      get () {
        return this.value
      },
      set (value) {
        this.$emit('input', value)
      }
    }
  },
  data () {
    return {
      options: [
        {
          label: 'in/valid',
          value: undefined
        },
        {
          label: 'only valid',
          value: true
        },
        {
          label: 'only invalid',
          value: false
        }
      ]
    }
  },
  mounted () {
    const params = URLParamsToJSON(location.href)
    this.optionValue = params.validity
  }
}
</script>
