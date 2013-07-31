package
{
	/**
	 * ...
	 * @author Matt Bury
	 * @version 2013.07.17.00
	 */
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.net.URLRequest;
	import flash.text.*;
	
	public class ImageLoader extends Sprite
	{
		private var _loader:Loader;
		private var _url:String;
		
		/**
		 * Constructor
		 */
		public function ImageLoader() {
			_loader = new Loader();
			configureListeners(_loader.contentLoaderInfo);
		}
		
		/**
		 * Load image
		 * @param	url:String URL of the image to load
		 */
		public function load(url:String):void {
			var request:URLRequest = new URLRequest(url);
			_loader.load(request);
		}
		
		/**
		 * Add listeners to Loader object
		 * @param	dispatcher:flash.events.IEventDispatcher
		 */
		private function configureListeners(dispatcher:IEventDispatcher):void {
			dispatcher.addEventListener(Event.COMPLETE, loaderComplete);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityError);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioError);
		}
		
		/**
		 * Remove listeners from Loader object
		 * @param	dispatcher:flash.events.IEventDispatcher
		 */
		private function removeListeners(dispatcher:IEventDispatcher):void {
			dispatcher.removeEventListener(Event.COMPLETE, loaderComplete);
			dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityError);
			dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, ioError);
		}
		
		/**
		 * Image has successfully loaded
		 * @param	event:flash.events.Event
		 */
		private function loaderComplete(event:Event):void {
			removeListeners(_loader);
			addChild(_loader);
		}
		
		/**
		 * Load image failed so report error messages
		 * @param	event:flash.events.SecurityErrorEvent
		 */
		private function securityError(event:SecurityErrorEvent):void {
			removeListeners(_loader);
			displayError(event.toString());
		}
		
		/**
		 * Load image failed so report error messages
		 * @param	event:flash.events.IOErrorEvent
		 */
		private function ioError(event:IOErrorEvent):void {
			removeListeners(_loader);
			displayError(event.toString());
		}
		
		/**
		 * Display error message from load event
		 * @param	str:String error event as string
		 */
		private function displayError(str:String):void {
			var f:TextFormat = new TextFormat("Charis SIL", 12, 0);
			var tf:TextField = new TextField();
			tf.defaultTextFormat = f;
			tf.background = true;
			tf.wordWrap = true;
			tf.width = 200;
			tf.height = 150;
			tf.text = str;
			addChild(tf);
		}
	}
}