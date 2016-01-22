sizeOf = Npm.require 'image-size'
mime = Npm.require 'mime-types'

@RocketChatAssetsInstance = new RocketChatFile.GridFS
	name: 'assets'


assets =
	'favicon.ico':
		label: 'favicon.ico'
		defaultUrl: 'favicon.ico?v=3'
		constraints:
			type: 'image'
			extension: 'ico'
			width: undefined
			height: undefined
	'favicon.svg':
		label: 'favicon.svg'
		defaultUrl: '/images/logo/icon.svg?v=3'
		constraints:
			type: 'image'
			extension: 'svg'
			width: undefined
			height: undefined
	'favicon_64.png':
		label: 'favicon.png (64x64)'
		defaultUrl: 'images/logo/favicon-64x64.png?v=3'
		constraints:
			type: 'image'
			extension: 'png'
			width: 64
			height: 64
	'favicon_96.png':
		label: 'favicon.png (96x96)'
		defaultUrl: 'images/logo/favicon-96x96.png?v=3'
		constraints:
			type: 'image'
			extension: 'png'
			width: 96
			height: 96
	'favicon_128.png':
		label: 'favicon.png (128x128)'
		defaultUrl: 'images/logo/favicon-128x128.png?v=3'
		constraints:
			type: 'image'
			extension: 'png'
			width: 128
			height: 128
	'favicon_192.png':
		label: 'favicon.png (192x192)'
		defaultUrl: 'images/logo/android-chrome-192x192.png?v=3'
		constraints:
			type: 'image'
			extension: 'png'
			width: 192
			height: 192
	'favicon_256.png':
		label: 'favicon.png (256x256)'
		defaultUrl: 'images/logo/favicon-256x256.png?v=3'
		constraints:
			type: 'image'
			extension: 'png'
			width: 256
			height: 256


RocketChat.settings.addGroup 'Assets'
for key, value of assets
	RocketChat.settings.add "Assets_#{key}", '', { type: 'asset', group: 'Assets', fileConstraints: value.constraints, i18nLabel: value.label, asset: key }


Meteor.methods
	unsetAsset: (asset) ->
		unless Meteor.userId()
			throw new Meteor.Error 'invalid-user', "[methods] unsetAsset -> Invalid user"

		hasPermission = RocketChat.authz.hasPermission Meteor.userId(), 'manage-assets'
		unless hasPermission
			throw new Meteor.Error 'manage-assets-not-allowed', "[methods] unsetAsset -> Manage assets not allowed"

		if not assets[asset]?
			throw new Meteor.Error "Invalid_asset"

		RocketChatAssetsInstance.deleteFile asset
		RocketChat.settings.clearById "Assets_#{asset}"


Meteor.methods
	setAsset: (binaryContent, contentType, asset) ->
		unless Meteor.userId()
			throw new Meteor.Error 'invalid-user', "[methods] setAsset -> Invalid user"

		hasPermission = RocketChat.authz.hasPermission Meteor.userId(), 'manage-assets'
		unless hasPermission
			throw new Meteor.Error 'manage-assets-not-allowed', "[methods] unsetAsset -> Manage assets not allowed"

		if not assets[asset]?
			throw new Meteor.Error "Invalid_asset"

		if mime.extension(contentType) isnt assets[asset].constraints.extension
			throw new Meteor.Error "Invalid_file_type", contentType

		file = new Buffer(binaryContent, 'binary')

		if assets[asset].constraints.width? or assets[asset].constraints.height?
			dimensions = sizeOf file

			if assets[asset].constraints.width? and assets[asset].constraints.width isnt dimensions.width
				throw new Meteor.Error "Invalid_file_width"

			if assets[asset].constraints.height? and assets[asset].constraints.height isnt dimensions.height
				throw new Meteor.Error "Invalid_file_height"

		rs = RocketChatFile.bufferToStream file
		RocketChatAssetsInstance.deleteFile asset
		ws = RocketChatAssetsInstance.createWriteStream asset, contentType
		ws.on 'end', Meteor.bindEnvironment ->
			Meteor.setTimeout ->
				RocketChat.settings.updateById "Assets_#{asset}", "/assets/#{asset}"
			, 200

		rs.pipe ws
		return


WebApp.connectHandlers.use '/assets/', (req, res, next) ->
	params =
		asset: decodeURIComponent(req.url.replace(/^\//, '').replace(/\?.*$/, ''))

	file = RocketChatAssetsInstance.getFileWithReadStream params.asset

	# res.setHeader 'Content-Disposition', 'inline'

	if not file?
		if assets[params.asset]?.defaultUrl?
			res.writeHead 301,
				Location: Meteor.absoluteUrl(assets[params.asset].defaultUrl)
		else
			res.writeHead 404
		res.end()
		return

	reqModifiedHeader = req.headers["if-modified-since"];
	if reqModifiedHeader?
		if reqModifiedHeader == file.uploadDate?.toUTCString()
			res.setHeader 'Last-Modified', reqModifiedHeader
			res.writeHead 304
			res.end()
			return

	res.setHeader 'Cache-Control', 'public, max-age=0'
	res.setHeader 'Expires', '-1'
	res.setHeader 'Last-Modified', file.uploadDate?.toUTCString() or new Date().toUTCString()
	res.setHeader 'Content-Type', file.contentType
	res.setHeader 'Content-Length', file.length

	file.readStream.pipe res
	return
