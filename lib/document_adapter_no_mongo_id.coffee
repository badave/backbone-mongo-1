JSONUtils = require './json_utils'
BackboneRelational = require './backbone_relational'

module.exports = class DocumentAdapter_NoMongoId

  @idAttribute = 'id'

  @modelFindQuery: (model) -> return {id: model.get('id')}

  @nativeToModel: (doc, model_type) ->
    return null unless doc

    # work around for Backbone Relational
    return BackboneRelational.findOrCreate(model_type, (new model_type()).parse(@nativeToAttributes(doc)))

  @nativeToAttributes: (doc) ->
    return {} unless doc
    doc[key] = JSONUtils.JSONToValue(value) for key, value of doc
    delete doc._id
    return doc

  @attributesToNative: (attributes) ->
    return {} unless attributes
    attributes[key] = JSONUtils.valueToJSON(value) for key, value of attributes
    delete attributes._id
    return attributes