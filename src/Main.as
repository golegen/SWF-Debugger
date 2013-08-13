/**
 * SWF Activity Module Debugger displays information passed in from the SWF Activity Module and interacts with Moodle's AMFPHP services.
 * Please note:
 * lib/components.swc library contains all the standard Flash UI and video components in case you want to extend this app to include more features and want to use components instead of writing your own code.
 * lib/fonts/CHARISSIL-R.TTF (Charis SIL) is a non-standard free and open source font that supports the International Phonetic Alphabet. More info on Charis SIL: http://www-01.sil.org/computing/catalog/show_software.asp?id=112. Charis SIL licence: http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=OFL
 */

package 
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.events.IOErrorEvent;
	import flash.events.IEventDispatcher;
	import flash.events.SecurityErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import fl.controls.UIScrollBar;
	import com.adobe.images.PNGEncoder; // Static class, doesn't need instantiating
	import com.matbury.sam.data.FlashVars;
	
	/**
	 * @author Matt Bury
	 * @version 2013.07.17.00
	 */
	public class Main extends Sprite 
	{ 
		[Embed(source = '../lib/fonts/CHARISSIL-R.TTF', fontName = 'Charis SIL', embedAsCFF="false", mimeType="application/x-font")] private var CharisSILfont:Class;
		private var _buttons:Array;
		private var _loadSmilButton:Button;
		private var _urlLoader:URLLoader;
		private var _smil:XML;
		private var _namespace:Namespace; // Namespace must be a class level variable to avoid scoping issues
		private var _seqLength:int;
		private var _smilIndex:int = 0;
		private var _displayContentButton:Button;
		private var _elements:Array; // All DisplayObjects for one _smil.body.seq[i] node
		private var _indexButtons:Array; // Index buttons corresponding to each _smil.body.seq[i] node
		private var _flashVarsButton:Button;
		private var _flashPlayerInfoButton:Button;
		private var _gradeButton:Button;
		private var _sendGrade:SendGrade;
		private var _send:Button;
		private var _snapshotButton:Button;
		private var _snapshot:Snapshot;
		private var _increment:Button;
		private var _decrement:Button;
		private var _fullscreen:Button;
		private var _exit:Button;
		private var _stageInfoText:TextField;
		private var _displayText:TextField;
		private var _scrollBar:UIScrollBar;
		private var _error:String = "";
		
		/**
		 * Class function
		 */
		public function Main():void {
			if (stage) init(); // Wait till we're fully initialised
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		/**
		 * App starts here
		 * @param	event:flash.events.Event
		 */
		private function init(event:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, resize);
			FlashVars.vars = this.root.loaderInfo.parameters;
			// The next two (commented out) lines allow you to debug this app in your Flash IDE: Uncomment and edit as necessary
			//FlashVars.xmlurl = "../../../../../moodle2data/repository/swfcontent/mmlcc/commonobjects/xml/common_objects.smil";
			//FlashVars.moodledata = "../../../../../moodle2data/repository/swfcontent/";
			initStageInfoText();
			initButtons();
			resize();
		}
		
		/**
		 * If user resizes the browser/app, adjust contents to fit new size
		 * @param	event:flash.events.Event
		 */
		private function resize(event:Event = null):void {
			positionButtons();
			positionIndexButtons();
			positionStageInfoText();
			positionDisplayText();
			positionElements();
			positionSendGrade();
			positionSnapshot();
		}
		
		/**
		 * Deletes all elements added to stage after init
		 */
		private function clearAll():void {
			deleteDisplayText();
			deleteElements();
			deleteIndexButtons();
			deleteSendGrade();
			deleteSnapshot();
		}
		
		/**
		 * Initialise UI buttons (top row)
		 */
		private function initButtons():void {
			_buttons = new Array();
			// Load SMIL
			_loadSmilButton = new Button("Load SMIL");
			_loadSmilButton.addEventListener(MouseEvent.MOUSE_UP, initLoadSmil);
			addChild(_loadSmilButton);
			_buttons.push(_loadSmilButton);
			// Decrement
			_decrement = new Button(" - ");
			_decrement.addEventListener(MouseEvent.MOUSE_UP, decrement);
			addChild(_decrement);
			_buttons.push(_decrement);
			// Display content
			_displayContentButton = new Button("Display Media");
			_displayContentButton.addEventListener(MouseEvent.MOUSE_UP, initElements);
			addChild(_displayContentButton);
			_buttons.push(_displayContentButton);
			// Increment
			_increment = new Button(" + ");
			_increment.addEventListener(MouseEvent.MOUSE_UP, increment);
			addChild(_increment);
			_buttons.push(_increment);
			// FlashVars
			_flashVarsButton = new Button("Show FlashVars");
			_flashVarsButton.addEventListener(MouseEvent.MOUSE_UP, initFlashVars);
			addChild(_flashVarsButton);
			_buttons.push(_flashVarsButton);
			// Flash Player info
			_flashPlayerInfoButton = new Button("Show Flash Player Info");
			_flashPlayerInfoButton.addEventListener(MouseEvent.MOUSE_UP, initFlashPlayerInfo);
			addChild(_flashPlayerInfoButton);
			_buttons.push(_flashPlayerInfoButton);
			// Grade
			_gradeButton = new Button("Send Grade");
			_gradeButton.addEventListener(MouseEvent.MOUSE_UP, initGrade);
			addChild(_gradeButton);
			_buttons.push(_gradeButton);
			// Snapshot
			_snapshotButton = new Button("Save Snapshot");
			_snapshotButton.addEventListener(MouseEvent.MOUSE_UP, initSnapshot);
			addChild(_snapshotButton);
			_buttons.push(_snapshotButton);
			// Fullscreen
			if (FlashVars.fullscreen != "undefined" && FlashVars.fullscreen != "false") {
				stage.addEventListener(FullScreenEvent.FULL_SCREEN, fullscreenEvent);
				_fullscreen = new Button("Fullscreen");
				_fullscreen.addEventListener(MouseEvent.MOUSE_UP, fullscreen);
				addChild(_fullscreen);
				_buttons.push(_fullscreen);
			}
			// Exit
			if(FlashVars.exiturl != "undefined") {
				_exit = new Button("Go to exit URL");
				_exit.addEventListener(MouseEvent.MOUSE_UP, exit);
				addChild(_exit);
				_buttons.push(_exit);
			}
		}
		
		/**
		 * Position UI buttons from top left, across top of screen
		 */
		private function positionButtons():void {
			if (_buttons) {
				var posX:uint = 0;
				var len:uint = _buttons.length;
				for (var i:uint = 0; i < len; i++)
				{
					_buttons[i].x = posX;
					posX += _buttons[i].width + 3;
				}
			}
		}
		
		/**
		 * Load SMIL or XML file
		 * @param	event:flash.events.MouseEvent
		 */
		private function initLoadSmil(event:MouseEvent = null):void {
			clearAll();
			initDisplayText();
			if (!_urlLoader) {
				_urlLoader = new URLLoader();
				configureListeners(_urlLoader);
				var request:URLRequest = new URLRequest(FlashVars.xmlurl);
				_urlLoader.load(request);
			} else if(_smil) {
				_displayText.text = "SMIL Data:\n\n" + _smil;
			} else {
				_displayText.text = _error;
			}
			resize();
		}
		
		/**
		 * Add listeners to URLLoader
		 * @param	dispatcher:flash.events.IEventDispatcher
		 */
		private function configureListeners(dispatcher:IEventDispatcher):void {
			dispatcher.addEventListener(Event.COMPLETE, urlLoaderComplete);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, urlSecurityError);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, urlIOError);
		}
		
		/**
		 * Remove listeners from URLLoader
		 * @param	dispatcher:flash.events.IEventDispatcher
		 */
		private function removeListeners(dispatcher:IEventDispatcher):void {
			dispatcher.removeEventListener(Event.COMPLETE, urlLoaderComplete);
			dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, urlSecurityError);
			dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, urlIOError);
		}
		
		/**
		 * SMIL or XML file successfully loaded,
		 * initialise _smil:XML classwide object and display details
		 * @param	event:flash.events.Event
		 */
		private function urlLoaderComplete(event:Event):void {
			removeListeners(_urlLoader);
			_smil = XML(_urlLoader.data);
			// Get any namespace properties to avoid parsing errors
			_namespace = new Namespace(_smil.name());
			default xml namespace = _namespace;
			_seqLength = _smil.body.seq.length();
			clearAll();
			initDisplayText();
			_displayText.text = "SMIL Data:\n\n Namespace = " + _smil.name() + " length = " + _seqLength + "\n\n" + _smil;
			initIndexButtons();
			resize();
		}
		
		/**
		 * SMIL or XML file failed to load, display details
		 * @param	event:flash.events.SecurityErrorEvent
		 */
		private function urlSecurityError(event:SecurityErrorEvent):void {
			removeListeners(_urlLoader);
			_smil = null;
			_error = "SMIL Data:\n\n" + event.toString();
			_displayText.text = _error;
		}
		
		/**
		 * SMIL or XML file failed to load, display details
		 * @param	event:flash.events.IOErrorEvent
		 */
		private function urlIOError(event:IOErrorEvent):void {
			removeListeners(_urlLoader);
			_smil = null;
			_error = "SMIL Data:\n\n" + event.toString();
			_displayText.text = _error;
		}
		
		/**
		 * Load and display multimedia content referenced by SMIL or XML file
		 * @param	event:flash.events.MouseEvent
		 */
		private function initElements(event:MouseEvent = null):void {
			if (_smil) {
				clearAll();
				initDisplayText();
				_elements = new Array();
				var len:uint = _smil.body.seq[_smilIndex]..img.length(); // Load images
				for (var i:uint = 0; i < len; i++) {
					try {
						var url:String = _smil.body.seq[_smilIndex]..img[i].@src;
						var img:ImageLoader = new ImageLoader();
						img.load(FlashVars.moodledata + url);
						addChildAt(img,0);
						_elements.push(img);
					} catch (e:Error) { // Display any error messages
						_displayText.text = "Error: " + e.message + "\n\n" + _displayText.text;
					}
				}
				len = _smil.body.seq[_smilIndex]..audio.length(); // Load audio
				for (i = 0; i < len; i++) {
					try {
						url = _smil.body.seq[_smilIndex]..audio[i].@src;
						var label:String = _smil.body.seq[_smilIndex]..audio[i].@id;
						var audio:AudioButton = new AudioButton(label);
						audio.load(FlashVars.moodledata + url);
						addChild(audio);
						_elements.push(audio);
					} catch (e:Error) { // Display any error messages
						_displayText.text = "Error: " + e.message + "\n\n" + _displayText.text;
					}
				}
			}
			resize();
		}
		
		/**
		 * Arrange loaded media content to fit stage
		 */
		private function positionElements():void {
			if (_elements) {
				var len:uint = _elements.length;
				var posY:int = 0;
				for (var i:uint = 0; i < len; i++) {
					_elements[i].x = stage.stageWidth - 200;
					_elements[i].y = posY;
					if (_elements[i].height > 0) {
						posY += _elements[i].height + 2;
					} else {
						posY += 152;
					}
				}
			}
		}
		
		/**
		 * Delete loaded media content
		 */
		private function deleteElements():void {
			if (_elements) {
				var len:uint = _elements.length;
				for (var i:uint = 0; i < len; i++) {
					removeChild(_elements[i]);
					_elements[i] = null;
				}
				_elements = null;
			}
		}
		
		/**
		 * Display current SMIL or XML <seq> node
		 */
		private function displayXML():void {
			initDisplayText();
			if (_smil) {
				_displayText.text = "SMIL node " + _smilIndex + ":\n\n" + _smil.body.seq[_smilIndex];
				parseNode();
			} else {
				_displayText.text = "Please load a valid SMIL or XML file.";
			}
			resize();
		}
		
		/**
		 * Parse and display contents of current SMIL or XML <seq> node as text
		 * This should show up any XML formatting errors
		 */
		private function parseNode():void {
			if (_smil) {
				var parLen:uint = _smil.body.seq[_smilIndex].par.length();
				_displayText.appendText("\n\n par length = " + parLen);
				for (var i:uint = 0; i < parLen; i++) {
					var elemLen:uint = _smil.body.seq[_smilIndex].par[i].text.length();
					var par:String;
					try {
						par = _smil.body.seq[_smilIndex].par[i].@id;
					} catch (e:Error) {
						par = e.message;
					}
					_displayText.appendText("\npar: " + i + ": " + par);
					for (var j:uint = 0; j < elemLen; j++) {
						var txt:String;
						try {
							txt = _smil.body.seq[_smilIndex].par[i].text[j];
						} catch (e:Error) {
							txt = e.message;
						}
						_displayText.appendText("\n	text: " + j + ": " + txt);
					}
					elemLen = _smil.body.seq[_smilIndex].par[i].audio.length();
					for (j = 0; j < elemLen; j++) {
						var id:String;
						try {
							id = _smil.body.seq[_smilIndex].par[i].audio[j].@id;
						} catch (e:Error) {
							id = e.message;
						}
						_displayText.appendText("\n	id " + j + ": " + id);
						var pron:String;
						try {
							pron = _smil.body.seq[_smilIndex].par[i].audio[j].@pron;
						} catch (e:Error) {
							pron = e.message;
						}
						_displayText.appendText("\n		pron " + j + ": " + pron);
						var audio:String;
						try {
							audio = _smil.body.seq[_smilIndex].par[i].audio[j].@src;
						} catch (e:Error) {
							audio = e.message;
						}
						_displayText.appendText("\n		audio " + j + ": " + audio);
					}
					elemLen = _smil.body.seq[_smilIndex].par[i].img.length();
					for (j = 0; j < elemLen; j++) {
						var img:String;
						try {
							img = _smil.body.seq[_smilIndex].par[i].img[j].@src;
						} catch (e:Error) {
							img = e.message;
						}
						_displayText.appendText("\n	img " + j + ": " + img);
					}
				}
			}
		}
		
		/**
		 * Display previous media content SMIL or XML node
		 * @param	event:flash.events.MouseEvent
		 */
		private function decrement(event:MouseEvent = null):void {
			if (_smil) {
				if (_smilIndex > 0) {
					_smilIndex--;
				} else {
					_smilIndex = _seqLength - 1; // Wrap around
				}
				displayXML();
			}
		}
		
		/**
		 * Display next media content SMIL or XML node
		 * @param	event:flash.events.MouseEvent
		 */
		private function increment(event:MouseEvent = null):void {
			if (_smil) {
				if (_smilIndex < _seqLength - 1) {
					_smilIndex++;
				} else {
					_smilIndex = 0; // Wrap around
				}
				displayXML();
			}
		}
		
		/**
		 * Create a numbered button for each SMIL or XML <seq> node 
		 */
		private function initIndexButtons():void {
			if (!_indexButtons) {
				_indexButtons = new Array();
				for (var i:uint = 0; i < _seqLength; i++) {
					var b:Button = new Button(String(i), i);
					b.addEventListener(MouseEvent.MOUSE_UP, indexUp);
					addChild(b);
					_indexButtons.push(b);
				}
			}
		}
		
		/**
		 * Position the numbered <seq> node buttons from bottom left along bottom of screen
		 */
		private function positionIndexButtons():void {
			if (_indexButtons) {
				var len:uint = _indexButtons.length;
				var posX:int = 0;
				var posY:int = stage.stageHeight - 24;
				var rows:int = 1; // Count the number of rows
				for (var i:uint = 0; i < len; i++) {
					_indexButtons[i].x = posX;
					_indexButtons[i].y = posY;
					posX += _indexButtons[i].width + 2;
					// Wrap rows around is stage width is too narrow
					if (posX > stage.stageWidth - _indexButtons[i].width) {
						posX = 0;
						posY += _indexButtons[i].height + 2;
						rows += 1;
					}
				}
				// If buttons have wrapped around, move them up to make them visible
				if(posY > stage.stageHeight - 24) {
					for (i = 0; i < len; i++) {
						_indexButtons[i].y -= rows * 24;
					}
				}
			}
		}
		
		/**
		 * Display media content of corresponding SMIL or XML <seq> button
		 * @param	event:flash.events.MouseEvent
		 */
		private function indexUp(event:MouseEvent):void {
			_smilIndex = event.currentTarget.i;
			displayXML();
		}
		
		/**
		 * Delete all SMIL or XML <seq> buttons
		 */
		private function deleteIndexButtons():void {
			if (_indexButtons) {
				var len:uint = _indexButtons.length;
				for (var i:uint = 0; i < len; i++) {
					_indexButtons[i].removeEventListener(MouseEvent.MOUSE_UP, indexUp);
					removeChild(_indexButtons[i]);
					_indexButtons[i] = null;
				}
				_indexButtons = null;
			}
		}
		
		
		/**
		 * Display all FlashVars passed in through Flash embed code
		 * @param	event:flash.events.MouseEvent
		 */
		private function initFlashVars(event:MouseEvent = null):void {
			clearAll();
			initDisplayText();
			_displayText.text = "FlashVars:\n";
			for (var s:String in this.root.loaderInfo.parameters) {
				_displayText.appendText("\n" + s + " = " + this.root.loaderInfo.parameters[s]);
			}
			resize();
		}
		
		/**
		 * Display current width and height of stage
		 */
		private function initStageInfoText():void {
			var tf:TextFormat = new TextFormat("Trebuchet MS", 14, 0, false);
			_stageInfoText = new TextField();
			_stageInfoText.defaultTextFormat = tf;
			_stageInfoText.autoSize = TextFieldAutoSize.LEFT;
			_stageInfoText.selectable = false;
			_stageInfoText.text = "";
			addChild(_stageInfoText);
		}
		
		/**
		 * Position current width and height of stage text
		 */
		private function positionStageInfoText():void {
			if (_stageInfoText) {
				_stageInfoText.text = "width: " + stage.stageWidth + " | height: " + stage.stageHeight;
				_stageInfoText.x = stage.stageWidth * 0.5 - (_stageInfoText.width * 0.5);
				if (_indexButtons) {
					_stageInfoText.y = _indexButtons[0].y - _stageInfoText.height;
				} else {
					_stageInfoText.y = stage.stageHeight - _stageInfoText.height;
				}
			}
		}
		
		/**
		 * Display details about user's hardware, OS, and software environment
		 * @param	event:flash.events.MouseEvent
		 */
		private function initFlashPlayerInfo(event:MouseEvent = null):void {
			clearAll();
			initDisplayText();
			_displayText.text = "Flash Flayer info\n\nSystem:";
			_displayText.appendText("\n free memory = " + System.freeMemory + " bytes");
			_displayText.appendText("\n IME = " + System.ime + " ");
			_displayText.appendText("\n private memory = " + System.privateMemory + " bytes");
			_displayText.appendText("\n total memory = " + System.totalMemory + " bytes");
			_displayText.appendText("\n\nCapabilities:");
			_displayText.appendText("\n av Hardware Disable = " + Capabilities.avHardwareDisable + " ");
			_displayText.appendText("\n cpu Architecture = " + Capabilities.cpuArchitecture + " ");
			_displayText.appendText("\n has Accessibility = " + Capabilities.hasAccessibility + " ");
			_displayText.appendText("\n has Audio = " + Capabilities.hasAudio + " ");
			_displayText.appendText("\n has Audio Encoder = " + Capabilities.hasAudioEncoder + " ");
			_displayText.appendText("\n has Embedded Video = " + Capabilities.hasEmbeddedVideo + " ");
			_displayText.appendText("\n has IME = " + Capabilities.hasIME + " ");
			_displayText.appendText("\n has MP3 = " + Capabilities.hasMP3 + " ");
			_displayText.appendText("\n has Printing = " + Capabilities.hasPrinting + " ");
			_displayText.appendText("\n has Screen Broadcast = " + Capabilities.hasScreenBroadcast + " ");
			_displayText.appendText("\n has Screen Playback = " + Capabilities.hasScreenPlayback + " ");
			_displayText.appendText("\n has Streaming Audio = " + Capabilities.hasStreamingAudio + " ");
			_displayText.appendText("\n has Streaming Video = " + Capabilities.hasStreamingVideo + " ");
			_displayText.appendText("\n has TLS = " + Capabilities.hasTLS + " ");
			_displayText.appendText("\n has Video Encoder = " + Capabilities.hasVideoEncoder + " ");
			_displayText.appendText("\n is Debugger = " + Capabilities.isDebugger + " ");
			_displayText.appendText("\n language = " + Capabilities.language + " ");
			_displayText.appendText("\n local File Read Disabled = " + Capabilities.localFileReadDisable + " ");
			_displayText.appendText("\n manufacturer = " + Capabilities.manufacturer + " ");
			_displayText.appendText("\n max Level IDC = " + Capabilities.maxLevelIDC + " ");
			_displayText.appendText("\n os = " + Capabilities.os + " ");
			_displayText.appendText("\n pixel Aspect Ratio = " + Capabilities.pixelAspectRatio + " ");
			_displayText.appendText("\n player Type = " + Capabilities.playerType + " ");
			_displayText.appendText("\n screen Color = " + Capabilities.screenColor + " ");
			_displayText.appendText("\n screen DPI = " + Capabilities.screenDPI + " ");
			_displayText.appendText("\n screen Resolution X = " + Capabilities.screenResolutionX + " pixels");
			_displayText.appendText("\n screen Resolution Y = " + Capabilities.screenResolutionY + " pixels");
			_displayText.appendText("\n supports 32 Bit Processes = " + Capabilities.supports32BitProcesses + " ");
			_displayText.appendText("\n supports 64 Bit Processes = " + Capabilities.supports64BitProcesses + " ");
			_displayText.appendText("\n touchscreen type = " + Capabilities.touchscreenType + " ");
			_displayText.appendText("\n Flash Player version = " + Capabilities.version  + " ");
			resize();
		}
		
		/**
		 * Initialise UI to send grades to AMFPHP gateway
		 * @param	event:flash.events.MouseEvent
		 */
		private function initGrade(event:MouseEvent = null):void {
			clearAll();
			_sendGrade = new SendGrade();
			addChild(_sendGrade);
			_send = new Button("Send grade");
			_send.addEventListener(MouseEvent.MOUSE_UP, sendUp);
			addChild(_send);
			resize();
		}
		
		/**
		 * Send grade
		 * @param	event:flash.events.MouseEvent
		 */
		private function sendUp(event:MouseEvent = null):void {
			_sendGrade.sendGrade();
		}
		
		private function positionSendGrade():void {
			if (_sendGrade) {
				_sendGrade.x = 10;
				_sendGrade.y = 60;
				_send.x = (_sendGrade.x + _sendGrade.width) - _send.width;
				_send.y = _sendGrade.y;
			}
		}
		
		private function deleteSendGrade():void {
			if (_sendGrade) {
				removeChild(_sendGrade);
				_sendGrade = null;
			}
			if (_send) {
				removeChild(_send);
				_send.removeEventListener(MouseEvent.MOUSE_UP, sendUp);
				_send = null;
			}
		}
		
		private function initSnapshot(event:MouseEvent = null):void {
			clearAll();
			if (!_snapshot) {
				_snapshot = new Snapshot();
				addChild(_snapshot);
			}
			resize();
			_snapshot.save();
		}
		
		private function positionSnapshot():void {
			if (_snapshot) {
				_snapshot.x = stage.stageWidth * 0.5 - (_snapshot.width * 0.5);
				_snapshot.y = stage.stageHeight * 0.5 - (_snapshot.height * 0.5);
			}
		}
		
		private function deleteSnapshot():void {
			if (_snapshot) {
				removeChild(_snapshot);
				_snapshot = null;
			}
		}
		
		// stage.allowsFullScreenInteractive was introduced in Flash Player 11.3
		// Won't work for Flash Player 11.2 (for Linux users) so use workaround
		private function fullscreen(event:MouseEvent = null):void {
			switch(stage.displayState) {
				case StageDisplayState.NORMAL:
					if (FlashVars.fullscreen == "allowFullScreenInteractive") {
						stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
					} else {
						stage.displayState = StageDisplayState.FULL_SCREEN;
					}
					break;
					
				case StageDisplayState.FULL_SCREEN:
					stage.displayState = StageDisplayState.NORMAL;
					break;
					
				case StageDisplayState.FULL_SCREEN_INTERACTIVE:
					stage.displayState = StageDisplayState.NORMAL;
					break;
					
				default:
					// no default
			}
			fullscreenEvent();
		}
		
		private function fullscreenEvent(event:FullScreenEvent = null):void {
			if (stage.displayState == StageDisplayState.NORMAL) {
				_fullscreen.label = "Fullscreen";
			} else {
				_fullscreen.label = "Exit fullscreen";
			}
			initDisplayText();
			positionDisplayText();
			_displayText.text = "allowsFullScreen = " + FlashVars.fullscreen + "\nstage.displayState = " + stage.displayState;
			resize();
		}
		
		private function exit(event:MouseEvent):void {
			var request:URLRequest = new URLRequest(FlashVars.exiturl);
			navigateToURL(request, "_self");
		}
		
		/**
		 * Initialise text area for displaying text; SMIL, XML, FlashVars, etc.
		 * and add UIScrollBar component from lib/components.swc::fl.controls.UIScrollBar
		 */
		private function initDisplayText():void {
			if (!_displayText) {
				var tf:TextFormat = new TextFormat("Charis SIL", 14, 0, false);
				_displayText = new TextField();
				_displayText.defaultTextFormat = tf;
				_displayText.wordWrap = true;
				_displayText.multiline = true;
				_displayText.embedFonts = true;
				var dsf:DropShadowFilter = new DropShadowFilter(1, 45, 0xFFFFFF, 1, 2, 2, 2);
				_displayText.filters = [dsf];
				_displayText.text = " ";
				addChild(_displayText);
				_scrollBar = new UIScrollBar();
				addChild(_scrollBar);
			}
		}
		
		/**
		 * Adjust text area to fit available space on screen
		 */
		private function positionDisplayText():void {
			if (_displayText) {
				_displayText.width = stage.stageWidth - 16;
				_displayText.height = stage.stageHeight - 60;
				_displayText.x = 0;
				_displayText.y = 30;
				_scrollBar.move(_displayText.x + _displayText.width, _displayText.y);
				_scrollBar.setSize(_scrollBar.width, _displayText.height);
				_scrollBar.scrollTarget = _displayText;
			}
		}
		
		/**
		 * Delete text area
		 */
		private function deleteDisplayText():void {
			if (_displayText) {
				removeChild(_displayText);
				_displayText = null;
			}
		}
	}
} // End of class