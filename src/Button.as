package
{
	/**
	 * ...
	 * @author Matt Bury
	 * @version 2013.07.17.00
	 */
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class Button extends Sprite
	{
		private var _dsf:DropShadowFilter;
		private var _t:TextField;
		private var _i:int;
		
		/**
		 * Constructor
		 * @param	label:String text that appears as button label
		 * @param	i:int index id of button
		 */
		public function Button(label:String = "label", i:int = -1) {
			_i = i;
			initText(label);
			mouseChildren = false;
			buttonMode = true;
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			_dsf = new DropShadowFilter(2, 45, 0, 1, 2, 2);
			filters = [_dsf];
		}
		
		/**
		 * Initialise text field for label text
		 * @param	label:String text that appears as button label
		 */
		private function initText(label:String):void {
			var tf:TextFormat = new TextFormat("Charis SIL", 14, 0, false);
			_t = new TextField();
			_t.selectable = false;
			_t.border = true;
			_t.background = true;
			_t.defaultTextFormat = tf;
			_t.autoSize = TextFieldAutoSize.LEFT;
			_t.text = " " + label + " ";
			addChild(_t);
		}
		
		/**
		 * Manages button UI behaviour
		 * @param	event:flash.events.MouseEvent
		 */
		private function mouseDown(event:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			parent.parent.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			x += 2;
			y += 2;
			filters = [];
		}
		
		/**
		 * Manages button UI behaviour
		 * @param	event:flash.events.MouseEvent
		 */
		private function mouseUp(event:MouseEvent):void {
			parent.parent.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			x -= 2;
			y -= 2;
			filters = [_dsf];
		}
		
		/**
		 * Setter method for button label text
		 */
		public function set label(str:String):void {
			_t.text = str;
		}
		
		/**
		 * Setter method to enable/disable button mode
		 */
		public function set enabled(tf:Boolean):void {
			if(tf) {
				addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				_t.selectable = false;
				mouseChildren = false;
				buttonMode = true;
			} else {
				removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				_t.selectable = true;
				mouseChildren = true;
				buttonMode = false;
			}
		}
		
		/**
		 * Setter method for button index
		 * @param i:int
		 */
		public function set i(i:int):void {
			_i = i;
		}
		
		/**
		 * Getter method for button index
		 * @return i:int
		 */
		public function get i():int {
			return _i;
		}
	}
}