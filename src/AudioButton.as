package
{
	/**
	 * ...
	 * @author Matt Bury
	 * @version 2013.07.17.00
	 */
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.net.URLRequest;
	
	public class AudioButton extends Button
	{
		private var _sound:Sound;
		private var _channel:SoundChannel;
		
		/**
		 * Constructor
		 * @param	label:String
		 * @param	i:int 
		 */
		public function AudioButton(label:String = "label", i:int = -1) {
			super.label = label;
			super.i = i;
		}
		
		/**
		 * Load audio file
		 * @param	url:String URL of an audio file to load and playback
		 */
		public function load(url:String):void {
			var request:URLRequest = new URLRequest(url);
			_sound = new Sound();
			configureListeners(_sound);
			_sound.load(request);
		}
		
		/**
		 * Add listeners to sound object
		 * @param	dispatcher:flash.events.IEventDispatcher
		 */
		private function configureListeners(dispatcher:IEventDispatcher):void {
			dispatcher.addEventListener(Event.COMPLETE, soundComplete);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioError);
		}
		
		/**
		 * Remove listeners from sound object
		 * @param	dispatcher:flash.events.IEventDispatcher
		 */
		private function removeListeners(dispatcher:IEventDispatcher):void {
			dispatcher.removeEventListener(Event.COMPLETE, soundComplete);
			dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, ioError);
		}
		
		/**
		 * Sound has successfully loaded so enable button mode
		 * @param	event:flash.events.Event
		 */
		private function soundComplete(event:Event):void {
			removeListeners(_sound);
			addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}
		
		/**
		 * Sound load failed so report error
		 * @param	event:flash.events.IOErrorEvent
		 */
		private function ioError(event:IOErrorEvent):void {
			removeListeners(_sound);
			super.label = ": IO" + event.text + " ";
			x -= width;
			super.enabled = false;
		}
		
		/**
		 * Play loaded sound
		 * @param	event:flash.events.MouseEvent
		 */
		private function mouseUp(event:MouseEvent = null):void {
			_channel = _sound.play();
		}
	}
}