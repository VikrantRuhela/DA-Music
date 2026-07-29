package com.vikrantruhela.datunes

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log

class DAWidgetProvider : AppWidgetProvider() {
    companion object {
        const val ACTION_PLAY_PAUSE = "com.vikrantruhela.datunes.ACTION_PLAY_PAUSE"
        const val ACTION_NEXT = "com.vikrantruhela.datunes.ACTION_NEXT"
        const val ACTION_PREVIOUS = "com.vikrantruhela.datunes.ACTION_PREVIOUS"
        const val ACTION_SHUFFLE = "com.vikrantruhela.datunes.ACTION_SHUFFLE"
        const val ACTION_REPEAT = "com.vikrantruhela.datunes.ACTION_REPEAT"
        const val ACTION_FAVORITE = "com.vikrantruhela.datunes.ACTION_FAVORITE"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        Log.d("DAWidgetProvider", "onUpdate called. Refreshing widgets from cache.")
        WidgetUpdater.updateFromCache(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        Log.d("DAWidgetProvider", "onAppWidgetOptionsChanged called for widgetId: $appWidgetId. Refreshing from cache.")
        WidgetUpdater.updateFromCache(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        Log.d("DAWidgetProvider", "onReceive triggered with action: $action")
        if (action != null) {
            when (action) {
                ACTION_PLAY_PAUSE -> sendMediaCommand(context, "PLAY_PAUSE")
                ACTION_NEXT -> sendMediaCommand(context, "NEXT")
                ACTION_PREVIOUS -> sendMediaCommand(context, "PREVIOUS")
                ACTION_SHUFFLE -> sendMediaCommand(context, "SHUFFLE")
                ACTION_REPEAT -> sendMediaCommand(context, "REPEAT")
                ACTION_FAVORITE -> sendMediaCommand(context, "FAVORITE")
            }
        }
    }

    private fun sendMediaCommand(context: Context, command: String) {
        Log.d("DAWidgetProvider", "sendMediaCommand initiated for command: $command")
        val controller = DAApplication.instance?.getMediaController()
        if (controller != null) {
            Log.d("DAWidgetProvider", "  Found active MediaController. State = ${controller.playbackState?.state}")
            try {
                when (command) {
                    "PLAY_PAUSE" -> {
                        val state = controller.playbackState?.state
                        if (state == PlaybackStateCompat.STATE_PLAYING) {
                            Log.d("DAWidgetProvider", "    Dispatching PAUSE to transport controls.")
                            controller.transportControls.pause()
                        } else {
                            Log.d("DAWidgetProvider", "    Dispatching PLAY to transport controls.")
                            controller.transportControls.play()
                        }
                    }
                    "NEXT" -> {
                        Log.d("DAWidgetProvider", "    Dispatching SKIP_TO_NEXT to transport controls.")
                        controller.transportControls.skipToNext()
                    }
                    "PREVIOUS" -> {
                        Log.d("DAWidgetProvider", "    Dispatching SKIP_TO_PREVIOUS to transport controls.")
                        controller.transportControls.skipToPrevious()
                    }
                    "SHUFFLE" -> {
                        val currentMode = controller.shuffleMode
                        val nextMode = if (currentMode == PlaybackStateCompat.SHUFFLE_MODE_NONE) {
                            PlaybackStateCompat.SHUFFLE_MODE_ALL
                        } else {
                            PlaybackStateCompat.SHUFFLE_MODE_NONE
                        }
                        Log.d("DAWidgetProvider", "    Dispatching SHUFFLE mode update: $nextMode")
                        controller.transportControls.setShuffleMode(nextMode)
                    }
                    "REPEAT" -> {
                        val currentMode = controller.repeatMode
                        val nextMode = when (currentMode) {
                            PlaybackStateCompat.REPEAT_MODE_NONE -> PlaybackStateCompat.REPEAT_MODE_ALL
                            PlaybackStateCompat.REPEAT_MODE_ALL -> PlaybackStateCompat.REPEAT_MODE_ONE
                            else -> PlaybackStateCompat.REPEAT_MODE_NONE
                        }
                        Log.d("DAWidgetProvider", "    Dispatching REPEAT mode update: $nextMode")
                        controller.transportControls.setRepeatMode(nextMode)
                    }
                    "FAVORITE" -> {
                        Log.d("DAWidgetProvider", "    Dispatching FAVORITE toggle custom action.")
                        controller.transportControls.sendCustomAction("toggle_favorite", null)
                    }
                }
            } catch (e: Exception) {
                Log.e("DAWidgetProvider", "    Error dispatching command via MediaController: ${e.message}", e)
            }
        } else {
            // Fallback for standard playback controls when process is not active
            val keycode = when (command) {
                "PLAY_PAUSE" -> android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
                "NEXT" -> android.view.KeyEvent.KEYCODE_MEDIA_NEXT
                "PREVIOUS" -> android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS
                else -> 0
            }
            Log.d("DAWidgetProvider", "  MediaController is null. Using fallback intent broadcast with keycode: $keycode")
            if (keycode != 0) {
                try {
                    val mediaButtonIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                        component = ComponentName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
                        putExtra(Intent.EXTRA_KEY_EVENT, android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, keycode))
                    }
                    context.sendBroadcast(mediaButtonIntent)
                    
                    val mediaButtonIntentUp = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
                        component = ComponentName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
                        putExtra(Intent.EXTRA_KEY_EVENT, android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, keycode))
                    }
                    context.sendBroadcast(mediaButtonIntentUp)
                    Log.d("DAWidgetProvider", "  Fallback key broadcasts dispatched successfully.")
                } catch (e: Exception) {
                    Log.e("DAWidgetProvider", "  Error dispatching fallback key events: ${e.message}", e)
                }
            }
        }
    }
}
