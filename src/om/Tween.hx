package om;

import om.Time;
import om.ease.Linear;
import om.math.Interpolation;

class Tween {

	public static var list(default,null) = new Array<Tween>();

	public static inline function add( tween : Tween )
		list.push( tween );

	public static function remove( tween : Tween ) {
		var i = list.indexOf( tween );
		return if( i == -1 ) false else {
			list.splice( i, 1 );
			true;
		}
	}

	public static inline function removeAll()
		list = new Array<Tween>();

	public static function step( delta : Float ) : Bool {
		if( list.length == 0 )
			return false;
		var i = 0;
		while( i < list.length )
			list[i].update( delta ) ? i++ : list.splice( i, 1 );
		return true;
	}

	/** */
	public var isPlaying(default,null) = false;

	/** Duration in ms */
	public var duration(default,null) : Null<Float>;

	/** */
	public var target(default,null) : Dynamic;

    /** Time elapsed since start */
	public var time(default,null) : Float;

	var _valuesStart : Dynamic = {};
	var _valuesEnd : Dynamic = {};
	var _valuesStartRepeat : Dynamic = {};

	var _repeat = 0;
	var _yoyo = false;
	var _reversed = false;

	var _delayTime = 0.0;
	var _startTime = 0.0;

	var _easingFunction = Linear.None;
	var _chainedTweens = new Array<Tween>();

    var _onStartCallbackFired : Bool;
	var _onStartCallback : Void->Void;
	var _onUpdateCallback : Void->Void;
	var _onCompleteCallback : Void->Void;
	var _onStopCallback : Void->Void;

	public function new( target : Dynamic ) {
		this.target = target;
	}

	//public function start( time : Null<Float> = 0.0 ) : Tween {
	public function start() : Tween {

        this.time = Time.stamp();
        _startTime = this.time + _delayTime;

        _onStartCallbackFired = false;

		for( f in Reflect.fields( _valuesEnd ) ) {

			Reflect.setField( _valuesStart, f, Reflect.field( target, f ) );
			Reflect.setField( _valuesStart, f, Reflect.field( _valuesStart, f ) * 1.0 );

			var v = Reflect.field( _valuesStart, f );
			Reflect.setField( _valuesStartRepeat, f, (v != null) ? v : 0.0 );
		}

        Tween.add( this );

        isPlaying = true;

		return this;
	}

	public function stop() : Tween {

		if( !isPlaying )
			return this;

        isPlaying = false;

		Tween.remove( this );

		if( _onStopCallback != null ) _onStopCallback();

		return stopChainedTweens();
	}

	public function stopChainedTweens() : Tween {
		for( t in _chainedTweens ) t.stop();
		return this;
	}

	public function to( props : Dynamic, duration = 1000.0 ) : Tween {
		this._valuesEnd = props;
		this.duration = duration;
		return this;
	}

	public function delay( ms : Float ) : Tween {
		_delayTime = ms;
		return this;
	}

	public function repeat( times : Int ) : Tween {
		_repeat = times;
		return this;
	}

	public function yoyo( yes : Bool ) : Tween {
		_yoyo = yes;
		return this;
	}

	public function easing( f : Dynamic ) : Tween {
		_easingFunction = f;
		return this;
	}

	public function chain( args : Array<Tween> ) : Tween {
		_chainedTweens = args;
		return this;
	}

	public function onStart( f : Void->Void ) : Tween {
		_onStartCallback = f;
		return this;
	}

	public function onUpdate( f : Void->Void ) : Tween {
		_onUpdateCallback = f;
		return this;
	}

	public function onComplete( f : Void->Void ) : Tween {
		_onCompleteCallback = f;
		return this;
	}

	public function onStop( f : Void->Void ) : Tween {
		_onStopCallback = f;
		return this;
	}

	public function clearAllHandlers() : Tween {
		_onStartCallback = _onCompleteCallback = _onStopCallback = null;
		return this;
	}

	public function update( delta : Float ) : Bool {

        time += delta;

		if( time < _startTime )
			return true;

		if( !_onStartCallbackFired ) {
			if( _onStartCallback != null ) _onStartCallback();
			_onStartCallbackFired = true;
		}

		var elapsed = (time - _startTime) / duration;
		elapsed = elapsed > 1 ? 1 : elapsed;

		var value = _easingFunction( elapsed );

		for( f in Reflect.fields( _valuesEnd ) ) {
			var start : Null<Int> = Reflect.field( _valuesStart, f );
			if( start == null ) start = 0;
			var end = Reflect.field( _valuesEnd, f );
			Reflect.setField( target, f, start + (end - start) * value );
		}

		if( _onUpdateCallback != null ) {
			_onUpdateCallback();
		}

		if( elapsed == 1 ) {
			if( _repeat > 0 ) {
				if( Math.isFinite( _repeat ) ) {
					_repeat--;
				}
				for( prop in Reflect.fields( _valuesStartRepeat ) ) {
					if( _yoyo ) {
						var tmp = Reflect.field( _valuesStartRepeat, prop );
						Reflect.setField( _valuesStartRepeat, prop, Reflect.field( _valuesEnd, prop ) );
						Reflect.setField( _valuesEnd, prop, tmp );
						//_valuesStartRepeat[ prop ] = _valuesEnd[ prop ];
						//_valuesEnd[ prop ] = tmp;
					}
					Reflect.setField( _valuesStart, prop, Reflect.field( _valuesEnd, prop ) );
				}
				if( _yoyo ) {
					_reversed = !_reversed;
				}
				_startTime = time + _delayTime;
				return true;
			} else {
				isPlaying = false;
				if( _onCompleteCallback != null ) {
					_onCompleteCallback();
				}
				//for( t in _chainedTweens ) t.start( time );
				for( t in _chainedTweens ) t.start();
				return false;
			}
		}
		return true;
	}

}
