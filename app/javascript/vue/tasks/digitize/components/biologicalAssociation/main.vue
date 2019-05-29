<template>
  <div>
    <block-layout>
      <div slot="header">
        <h3>Biological Associations</h3>
      </div>
      <div slot="body">
        <div class="separate-bottom">
          <template>
            <h3 v-if="biologicalRelationship" class="relationship-title">
              <template v-if="flip">
                <span 
                  v-for="item in biologicalRelationship.object_biological_properties"
                  :key="item.id"
                  class="separate-right background-info"
                  v-html="item.name"/>
                <span
                  v-html="biologicalRelationship.inverted_name"/>
                <span 
                  v-for="item in biologicalRelationship.subject_biological_properties"
                  :key="item.id"
                  class="separate-left background-info"
                  v-html="item.name"/>
              </template>
              <template v-else>
                <span 
                  v-for="item in biologicalRelationship.subject_biological_properties"
                  :key="item.id"
                  class="separate-right background-info"
                  v-html="item.name"/>
                <span>{{ (biologicalRelationship.hasOwnProperty('label') ? biologicalRelationship.label : biologicalRelationship.name) }}</span>
                <span 
                  v-for="item in biologicalRelationship.object_biological_properties"
                  :key="item.id"
                  class="separate-left background-info"
                  v-html="item.name"/>
              </template>
              <button
                v-if="biologicalRelationship.inverted_name"
                class="separate-left button button-default flip-button"
                type="button"
                @click="flip = !flip">
                Flip
              </button>
              <span
                @click="biologicalRelationship = undefined; flip = false"
                class="separate-left"
                data-icon="reset"/>
            </h3>
            <h3
              class="subtle relationship-title"
              v-else>Choose relationship</h3>
          </template>

          <template>
            <h3
              v-if="biologicalRelation"
              class="relation-title">
              <span v-html="displayRelated"/>
              <span
                @click="biologicalRelation = undefined"
                class="separate-left"
                data-icon="reset"/>
            </h3>
            <h3
              v-else
              class="subtle relation-title">Choose relation</h3>
          </template>
        </div>

        <biological
          v-if="!biologicalRelationship"
          class="separate-bottom"
          @select="biologicalRelationship = $event"/>
        <related
          v-if="!biologicalRelation"
          class="separate-bottom separate-top"
          @select="biologicalRelation = $event"/>
        <new-citation
          class="separate-top"
          ref="citation"
          @create="citation = $event"
          :global-id="'globalId'"/>

        <div class="separate-top">
          <button
            type="button"
            :disabled="!validateFields"
            @click="addAssociation"
            class="normal-input button button-submit">Add
          </button>
        </div>
        <table-list 
          v-if="collectionObject.id"
          class="separate-top"
          :list="list"
          @delete="removeBiologicalRelationship"/>
        <table-list 
          v-else
          class="separate-top"
          :list="queueAssociations"/>
      </div>
    </block-layout>
  </div>
</template>
<script>

  import Biological from './biological.vue'
  import Related from './related.vue'
  import NewCitation from './newCitation.vue'
  import TableList from './table.vue'
  import BlockLayout from 'components/blockLayout.vue'

  import { GetterNames } from '../../store/getters/getters.js'

  import { CreateBiologicalAssociation, GetBiologicalRelationshipsCreated, DestroyBiologicalAssociation } from '../../request/resources.js'

  export default {
    components: {
      Biological,
      Related,
      NewCitation,
      BlockLayout,
      TableList
    },
    computed: {
      validateFields() {
        return this.biologicalRelationship && this.biologicalRelation
      },
      displayRelated() {
        if(this.biologicalRelation) {
          return (this.biologicalRelation['object_tag'] ? this.biologicalRelation.object_tag : this.biologicalRelation.label_html)
        }
        else {
          return undefined
        }
      },
      collectionObject() {
        return this.$store.getters[GetterNames.GetCollectionObject]
      }
    },
    data() {
      return {
        list: [],
        biologicalRelationship: undefined,
        biologicalRelation: undefined,
        citation: undefined,
        queueAssociations: [],
        flip: false,
      }
    },
    watch: {
      collectionObject(newVal, oldVal) {
        if(newVal.id) {
          GetBiologicalRelationshipsCreated(newVal.global_id).then(response => {
            this.list = response
            this.processQueue()
          })
        }
      },
    },
    methods: {
      addAssociation() {
        let data = {
          biologicalRelationship: this.biologicalRelationship,
          biologicalRelation: this.biologicalRelation,
          citation: this.citation
        }
        this.queueAssociations.push(data)
        this.biologicalRelationship = undefined
        this.biologicalRelation = undefined
        this.citation = undefined
        this.$refs.citation.cleanCitation()
        this.processQueue()
      },
      createAssociationObject(data) {
        return {
          biological_relationship_id: data.biologicalRelationship.id,
          object_global_id: data.biologicalRelation.global_id,
          subject_global_id: this.collectionObject.global_id,
          origin_citation_attributes: data.citation
        }
      },
      processQueue() {
        if(!this.collectionObject.id) return
        this.queueAssociations.forEach(item => {
          CreateBiologicalAssociation(this.createAssociationObject(item)).then(response => {
            this.list.push(response)
          })
        })
        this.queueAssociations = []
      },
      removeBiologicalRelationship(biologicalRelationship) {
        DestroyBiologicalAssociation(biologicalRelationship.id).then(() => {
          this.list.splice(this.list.findIndex((item) => {
            return item.id == biologicalRelationship.id
          }), 1)
        })
      }
    }
  }
</script>
<style lang="scss">
  .radial-annotator {
    .biological_relationships_annotator {
      overflow-y: scroll;
      .flip-button {
        min-width: 30px;
      }
      .relationship-title {
        margin-left: 1em
      }
      .relation-title {
        margin-left: 2em
      }
      .switch-radio {
        label {
          min-width: 95px;
        }
      }
      .background-info {
        padding: 3px;
        padding-left: 6px;
        padding-right: 6px;
        border-radius: 3px;
        background-color: #DED2F9;
      }
      textarea {
        padding-top: 14px;
        padding-bottom: 14px;
        width: 100%;
        height: 100px;
      }
      .pages {
        width: 86px;
      }
      .vue-autocomplete-input, .vue-autocomplete {
        width: 376px;
      }
    }
  }
</style>