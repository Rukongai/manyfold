
// Entry point for the build script in your package.json
import Rails from '@rails/ujs'
import $ from 'jquery' // Just needed for selectize

import 'masonry-layout'

import Cocooned from '@notus.sh/cocooned'

import Uppy from '@uppy/core'
import Dashboard from '@uppy/dashboard'
import XHR from '@uppy/xhr-upload'

import 'src/preview'
import 'src/bulk_edit'
import 'src/model_edit'
import 'src/tag'
import 'src/carousel'
import 'src/file_size_validation'

// Load i18n definitions
import { I18n } from 'i18n-js'
import locales from 'src/locales.json'
window.i18n = new I18n(locales)

window.$ = $

document.addEventListener('DOMContentLoaded', () => {
	Rails.start()
	const uppySettings = document.getElementById('uppy-dashboard')?.dataset
	new Uppy({
		restrictions: {
			allowedFileTypes: uppySettings.allowedFileTypes?.split(","),
			maxFileSize: +uppySettings.maxFileSize
		}
	})
		.use(Dashboard, {
			inline: true,
			target: '#uppy-dashboard',
			theme: 'auto'
		})
    .use(XHR, { endpoint: '/upload' })
  Cocooned.start()
})
