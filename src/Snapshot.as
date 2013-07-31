package
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import com.adobe.images.PNGEncoder;
	import com.matbury.sam.data.Amf;
	import com.matbury.sam.data.FlashVars;
	
	public class Snapshot extends Sprite
	{
		private var _w:int = 250;
		private var _h:int = 200;
		private var _len:uint = 20;
		private var _image:Sprite;
		private var _amf:Amf;
		private var _displayText:TextField;
		
		public function Snapshot() {
			initImage();
		}
		
		private function initImage():void {
			_image = new Sprite();
			for (var i:uint = 0; i < _len; i++) {
				_image.graphics.beginFill(Math.floor(Math.random() * 0xFFFFFF), Math.random());
				_image.graphics.drawCircle(Math.floor(Math.random() * _w) + (_w * 0.5), Math.floor(Math.random() * _h) + (_h * 0.7), Math.floor(Math.random() * _h));
				_image.graphics.endFill();
			}
			addChild(_image);
		}
		
		public function save():void {
			var bitmapData:BitmapData = new BitmapData(stage.stageWidth, stage.stageHeight);
			bitmapData.draw(_image);
			var byteArray:ByteArray = PNGEncoder.encode(bitmapData);
			sendImage(byteArray);
		}
		
		private function sendImage(byteArray:ByteArray):void {
			var obj:Object = new Object(); // create an object to hold data sent to the server
			obj.feedback = ""; // (String) optional
			obj.feedbackformat = Math.floor(getTimer() / 1000); // (int) elapsed time in seconds
			obj.gateway = FlashVars.gateway; // (String) AMFPHP gateway URL
			obj.instance = FlashVars.instance; // (int) Moodle instance ID
			obj.rawgrade = 0; // (Number) grade, normally 0 - 100 but depends on grade book settings
			obj.pushgrade = true; // To push or not push a grade
			obj.servicefunction = "Snapshot.amf_save_snapshot"; // (String) ClassName.method_name
			obj.swfid = FlashVars.swfid; // (int) activity ID
			obj.bytearray = byteArray;
			obj.imagetype = "png"; // PNGExport = png, JPGExport = jpg
			_amf = new Amf(); // create Flash Remoting API object
			_amf.addEventListener(Amf.GOT_DATA, gotDataHandler); // listen for server response
			_amf.addEventListener(Amf.FAULT, faultHandler); // listen for server fault
			_amf.getObject(obj); // send the data to the server
		}
		
			
		// Connection to AMFPHP succeeded
		// Manage returned data and inform user
		private function gotDataHandler(event:Event):void {
			// Clean up listeners
			_amf.removeEventListener(Amf.GOT_DATA, gotDataHandler);
			_amf.removeEventListener(Amf.FAULT, faultHandler);
			// Check if grade was sent successfully
			switch(_amf.obj.result) {
				//
				case "SUCCESS":
				showMessage(_amf.obj.message);
				navigateToImage(_amf.obj.imageurl);
				break;
				//
				case "NO_SNAPSHOT_DIRECTORY":
				showMessage(_amf.obj.message);
				break;
				//
				case "FILE_NOT_WRITTEN":
				showMessage(_amf.obj.message);
				break;
				//
				case "NO_PERMISSION":
				showMessage(_amf.obj.message);
				break;
				//
				default:
				showMessage(_amf.obj.message);
			}
		}
		
		// Connection to AMFPHP failed
		private function faultHandler(event:Event):void {
			// Clean up listeners
			_amf.removeEventListener(Amf.GOT_DATA, gotDataHandler);
			_amf.removeEventListener(Amf.FAULT, faultHandler);
			showMessage("Error: There was a problem. Your image was not saved.");
		}
		
		private function navigateToImage(url:String):void {
			// Open returned URL in a new window,
			var request:URLRequest = new URLRequest(url);
			navigateToURL(request,"_blank");
			// or...
			// redirect to Moodle grade book
			//var gradebook:String = FlashVars.gradebook;
			//navigateToURL(request,"_self");
		}
		
		private function showMessage(str:String):void {
			var f:TextFormat = new TextFormat("Charis SIL", 14, 0, false);
				_displayText = new TextField();
				_displayText.defaultTextFormat = f;
				_displayText.autoSize = TextFieldAutoSize.LEFT;
				_displayText.background = true;
				_displayText.multiline = true;
				_displayText.embedFonts = true;
				var dsf:DropShadowFilter = new DropShadowFilter(1, 45, 0, 1, 2, 2, 2);
				_displayText.filters = [dsf];
				_displayText.text = str;
				addChild(_displayText);
		}
	}
}