package  
{
	/**
	 * Sends grades to AMFPHP gateway
	 * @author Matt Bury
	 * @version 2013.07.17.00
	 */
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import com.matbury.sam.data.Amf;
	import com.matbury.sam.data.FlashVars;
	
	public class SendGrade extends Sprite
	{
		private var _amf:Amf; // AMFPHP gateway API interface
		private var _f:TextFormat;
		private var _grade:TextField;
		private var _seconds:TextField;
		private var _feedback:TextField;
		private var _results:TextField;
		private var _loader:URLLoader;
		
		/**
		 * Constructor
		 */
		public function SendGrade() {
			initInputs();
			initResults();
		}
		
		/**
		 * Initialise input text fields
		 */
		private function initInputs():void {
			_f = new TextFormat("Charis SIL", 14, 0);
			_grade = initInput(String(Math.floor(Math.random() * 100)));
			_grade.restrict = "0-9 .";
			addChild(_grade);
			_seconds = initInput(String(Math.round(Math.random() * 360)));
			_seconds.restrict = "0-9";
			_seconds.y = _grade.y + _grade.height + 4;
			addChild(_seconds);
			_feedback = initInput("Grade (in %) and duration (in seconds) have been randomly generated. This is some feedback text that is sent to the AMFPHP gateway. You can edit these if you wish. ", 500, 75);
			_feedback.wordWrap = true;
			_feedback.y = _seconds.y + _seconds.height + 4;
			addChild(_feedback);
		}
		
		/**
		 * Initialise and configure a text field
		 * @param	str:String text to add to text field
		 * @param	w:int text field width
		 * @param	h:int text field height
		 * @return t:flash.text.TextField
		 */
		private function initInput(str:String,w:int = 100, h:int = 25):TextField {
			var t:TextField = new TextField();
			t.type = TextFieldType.INPUT;
			t.border = true;
			t.background = true;
			t.defaultTextFormat = _f;
			t.text = str;
			t.width = w;
			t.height = h;
			return t;
		}
		
		/**
		 * Initialise text area to display AMFPHP results
		 */
		private function initResults():void {
			_results = new TextField();
			_results.defaultTextFormat = _f;
			_results.autoSize = TextFieldAutoSize.LEFT;
			_results.multiline = true;
			_results.text = "Results...";
			_results.y = _feedback.y + _feedback.height + 4;
			addChild(_results);
		}
		
		/**
		 * Send a grade to AMFPHP gateway
		 */
		public function sendGrade():void {
			var obj:Object = new Object();
			obj.gateway = FlashVars.gateway; // (String) AMFPHP gateway URL
			obj.swfid = FlashVars.swfid; // (int) activity ID
			obj.instance = FlashVars.instance; // (int) Moodle instance ID
			obj.servicefunction = "Grades.amf_grade_update";
			obj.rawgrade = Number(_grade.text);
			obj.feedbackformat = Number(_seconds.text);
			obj.feedback = _feedback.text;
			_amf = new Amf();
			_amf.addEventListener(Amf.GOT_DATA, gotDataHandler); // listen for server response
			_amf.addEventListener(Amf.FAULT, faultHandler); // listen for server fault
			_amf.getObject(obj); // send the data to the server
			_results.text = "grade: " + obj.rawgrade + "\nseconds: " + obj.feedbackformat + "\nSending grade...";
		}
		
		/**
		 * Connection to AMFPHP succeeded so manage returned data and inform user
		 * @param	event:flash.events.Event
		 */
		private function gotDataHandler(event:Event):void {
			// Clean up listeners
			_amf.removeEventListener(Amf.GOT_DATA, gotDataHandler);
			_amf.removeEventListener(Amf.FAULT, faultHandler);
			try {
				switch(_amf.obj.result) {
					//
					case "SUCCESS": // Grade sent and confirmed
					_results.appendText("\n" + _amf.obj.message);
					break;
					//
					case "NO_PERMISSION": // User doesn't have permission/capability
					_results.appendText("\n" + _amf.obj.message);
					break;
					//
					default: // Some other response from Grade.amf_grade_update
					_results.appendText("\n" + _amf.obj.message);
				}
			} catch(e:Error) { // Some other error
				_results.appendText("\n" + _amf.obj.message);
			}
		}
		
		/**
		 * Connection to AMFPHP failed so report error messages and info
		 * @param	event:flash.events.Event
		 */
		private function faultHandler(event:Event):void {
			// clean up listeners
			_amf.removeEventListener(Amf.GOT_DATA, gotDataHandler);
			_amf.removeEventListener(Amf.FAULT, faultHandler);
			// Display server errors
			var msg:String = "Error: ";
			for(var s:String in _amf.obj.info) { // trace out returned data
				_results.appendText("\n" + s + "=" + _amf.obj.info[s]);
			}
			sendURLVars();
		}
		
		/**
		 * Workaround for servers with PHP 5.4+ installed (Where AmfPHP 1.9 doesn't work)
		 */
		private function sendURLVars():void {
			_results.appendText("\n AmfPHP gateway failed. Now trying URLLoader... ");
			_loader = new URLLoader();
			configureListeners(_loader);
			var url:String = FlashVars.gradeupdate;
			//var url:String = "scripts/grade.php";
			var request:URLRequest = new URLRequest(url);
			var vars:URLVariables = new URLVariables();
			vars.instance = FlashVars.instance;
			vars.swfid = FlashVars.swfid;
			vars.rawgrade = Number(_grade.text);
			vars.feedbackformat = Number(_seconds.text);
			vars.feedback = _feedback.text;
			request.data = vars;
			request.method = URLRequestMethod.POST;
			try {
				_loader.load(request);
			} catch (e:Error) {
				_results.appendText("\n" + e.name + ", " + e.message);
			}
		}
		
        private function configureListeners(dispatcher:IEventDispatcher):void {
            dispatcher.addEventListener(Event.COMPLETE, complete);
            dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityError);
            dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioError);
        }
		
        private function removeListeners(dispatcher:IEventDispatcher):void {
            dispatcher.removeEventListener(Event.COMPLETE, complete);
            dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityError);
            dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, ioError);
        }
		
		private function complete(event:Event):void {
			var loader:URLLoader = URLLoader(event.target);
			removeListeners(loader);
            _results.appendText("\n loader.data: " + loader.data);
		}
		
		private function ioError(event:IOErrorEvent):void {
			var loader:URLLoader = URLLoader(event.target);
			removeListeners(loader);
			_results.appendText("\n IOError: " + event.text);
		}
		
		private function securityError(event:SecurityErrorEvent):void {
			var loader:URLLoader = URLLoader(event.target);
			removeListeners(loader);
			_results.appendText("\n SecurityError: " + event.text);
		}
	}
}