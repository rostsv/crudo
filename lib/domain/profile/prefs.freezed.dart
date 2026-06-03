// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prefs.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Prefs {

 Goal get goal; Unit get units; int? get dailyKcalTarget; int get streakThreshold; ReminderMode get reminderMode; bool get preOn; bool get atOn; bool get eodOn; bool get riskOn; int get preMin;
/// Create a copy of Prefs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrefsCopyWith<Prefs> get copyWith => _$PrefsCopyWithImpl<Prefs>(this as Prefs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Prefs&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.units, units) || other.units == units)&&(identical(other.dailyKcalTarget, dailyKcalTarget) || other.dailyKcalTarget == dailyKcalTarget)&&(identical(other.streakThreshold, streakThreshold) || other.streakThreshold == streakThreshold)&&(identical(other.reminderMode, reminderMode) || other.reminderMode == reminderMode)&&(identical(other.preOn, preOn) || other.preOn == preOn)&&(identical(other.atOn, atOn) || other.atOn == atOn)&&(identical(other.eodOn, eodOn) || other.eodOn == eodOn)&&(identical(other.riskOn, riskOn) || other.riskOn == riskOn)&&(identical(other.preMin, preMin) || other.preMin == preMin));
}


@override
int get hashCode => Object.hash(runtimeType,goal,units,dailyKcalTarget,streakThreshold,reminderMode,preOn,atOn,eodOn,riskOn,preMin);

@override
String toString() {
  return 'Prefs(goal: $goal, units: $units, dailyKcalTarget: $dailyKcalTarget, streakThreshold: $streakThreshold, reminderMode: $reminderMode, preOn: $preOn, atOn: $atOn, eodOn: $eodOn, riskOn: $riskOn, preMin: $preMin)';
}


}

/// @nodoc
abstract mixin class $PrefsCopyWith<$Res>  {
  factory $PrefsCopyWith(Prefs value, $Res Function(Prefs) _then) = _$PrefsCopyWithImpl;
@useResult
$Res call({
 Goal goal, Unit units, int? dailyKcalTarget, int streakThreshold, ReminderMode reminderMode, bool preOn, bool atOn, bool eodOn, bool riskOn, int preMin
});




}
/// @nodoc
class _$PrefsCopyWithImpl<$Res>
    implements $PrefsCopyWith<$Res> {
  _$PrefsCopyWithImpl(this._self, this._then);

  final Prefs _self;
  final $Res Function(Prefs) _then;

/// Create a copy of Prefs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? goal = null,Object? units = null,Object? dailyKcalTarget = freezed,Object? streakThreshold = null,Object? reminderMode = null,Object? preOn = null,Object? atOn = null,Object? eodOn = null,Object? riskOn = null,Object? preMin = null,}) {
  return _then(_self.copyWith(
goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as Goal,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as Unit,dailyKcalTarget: freezed == dailyKcalTarget ? _self.dailyKcalTarget : dailyKcalTarget // ignore: cast_nullable_to_non_nullable
as int?,streakThreshold: null == streakThreshold ? _self.streakThreshold : streakThreshold // ignore: cast_nullable_to_non_nullable
as int,reminderMode: null == reminderMode ? _self.reminderMode : reminderMode // ignore: cast_nullable_to_non_nullable
as ReminderMode,preOn: null == preOn ? _self.preOn : preOn // ignore: cast_nullable_to_non_nullable
as bool,atOn: null == atOn ? _self.atOn : atOn // ignore: cast_nullable_to_non_nullable
as bool,eodOn: null == eodOn ? _self.eodOn : eodOn // ignore: cast_nullable_to_non_nullable
as bool,riskOn: null == riskOn ? _self.riskOn : riskOn // ignore: cast_nullable_to_non_nullable
as bool,preMin: null == preMin ? _self.preMin : preMin // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Prefs].
extension PrefsPatterns on Prefs {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Prefs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Prefs() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Prefs value)  $default,){
final _that = this;
switch (_that) {
case _Prefs():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Prefs value)?  $default,){
final _that = this;
switch (_that) {
case _Prefs() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Goal goal,  Unit units,  int? dailyKcalTarget,  int streakThreshold,  ReminderMode reminderMode,  bool preOn,  bool atOn,  bool eodOn,  bool riskOn,  int preMin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Prefs() when $default != null:
return $default(_that.goal,_that.units,_that.dailyKcalTarget,_that.streakThreshold,_that.reminderMode,_that.preOn,_that.atOn,_that.eodOn,_that.riskOn,_that.preMin);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Goal goal,  Unit units,  int? dailyKcalTarget,  int streakThreshold,  ReminderMode reminderMode,  bool preOn,  bool atOn,  bool eodOn,  bool riskOn,  int preMin)  $default,) {final _that = this;
switch (_that) {
case _Prefs():
return $default(_that.goal,_that.units,_that.dailyKcalTarget,_that.streakThreshold,_that.reminderMode,_that.preOn,_that.atOn,_that.eodOn,_that.riskOn,_that.preMin);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Goal goal,  Unit units,  int? dailyKcalTarget,  int streakThreshold,  ReminderMode reminderMode,  bool preOn,  bool atOn,  bool eodOn,  bool riskOn,  int preMin)?  $default,) {final _that = this;
switch (_that) {
case _Prefs() when $default != null:
return $default(_that.goal,_that.units,_that.dailyKcalTarget,_that.streakThreshold,_that.reminderMode,_that.preOn,_that.atOn,_that.eodOn,_that.riskOn,_that.preMin);case _:
  return null;

}
}

}

/// @nodoc


class _Prefs extends Prefs {
  const _Prefs({this.goal = Goal.maintain, this.units = Unit.g, this.dailyKcalTarget, this.streakThreshold = 80, this.reminderMode = ReminderMode.fixed, this.preOn = true, this.atOn = true, this.eodOn = true, this.riskOn = true, this.preMin = 30}): assert(preMin >= 0, 'preMin must be >= 0'),super._();
  

@override@JsonKey() final  Goal goal;
@override@JsonKey() final  Unit units;
@override final  int? dailyKcalTarget;
@override@JsonKey() final  int streakThreshold;
@override@JsonKey() final  ReminderMode reminderMode;
@override@JsonKey() final  bool preOn;
@override@JsonKey() final  bool atOn;
@override@JsonKey() final  bool eodOn;
@override@JsonKey() final  bool riskOn;
@override@JsonKey() final  int preMin;

/// Create a copy of Prefs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrefsCopyWith<_Prefs> get copyWith => __$PrefsCopyWithImpl<_Prefs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Prefs&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.units, units) || other.units == units)&&(identical(other.dailyKcalTarget, dailyKcalTarget) || other.dailyKcalTarget == dailyKcalTarget)&&(identical(other.streakThreshold, streakThreshold) || other.streakThreshold == streakThreshold)&&(identical(other.reminderMode, reminderMode) || other.reminderMode == reminderMode)&&(identical(other.preOn, preOn) || other.preOn == preOn)&&(identical(other.atOn, atOn) || other.atOn == atOn)&&(identical(other.eodOn, eodOn) || other.eodOn == eodOn)&&(identical(other.riskOn, riskOn) || other.riskOn == riskOn)&&(identical(other.preMin, preMin) || other.preMin == preMin));
}


@override
int get hashCode => Object.hash(runtimeType,goal,units,dailyKcalTarget,streakThreshold,reminderMode,preOn,atOn,eodOn,riskOn,preMin);

@override
String toString() {
  return 'Prefs(goal: $goal, units: $units, dailyKcalTarget: $dailyKcalTarget, streakThreshold: $streakThreshold, reminderMode: $reminderMode, preOn: $preOn, atOn: $atOn, eodOn: $eodOn, riskOn: $riskOn, preMin: $preMin)';
}


}

/// @nodoc
abstract mixin class _$PrefsCopyWith<$Res> implements $PrefsCopyWith<$Res> {
  factory _$PrefsCopyWith(_Prefs value, $Res Function(_Prefs) _then) = __$PrefsCopyWithImpl;
@override @useResult
$Res call({
 Goal goal, Unit units, int? dailyKcalTarget, int streakThreshold, ReminderMode reminderMode, bool preOn, bool atOn, bool eodOn, bool riskOn, int preMin
});




}
/// @nodoc
class __$PrefsCopyWithImpl<$Res>
    implements _$PrefsCopyWith<$Res> {
  __$PrefsCopyWithImpl(this._self, this._then);

  final _Prefs _self;
  final $Res Function(_Prefs) _then;

/// Create a copy of Prefs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? goal = null,Object? units = null,Object? dailyKcalTarget = freezed,Object? streakThreshold = null,Object? reminderMode = null,Object? preOn = null,Object? atOn = null,Object? eodOn = null,Object? riskOn = null,Object? preMin = null,}) {
  return _then(_Prefs(
goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as Goal,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as Unit,dailyKcalTarget: freezed == dailyKcalTarget ? _self.dailyKcalTarget : dailyKcalTarget // ignore: cast_nullable_to_non_nullable
as int?,streakThreshold: null == streakThreshold ? _self.streakThreshold : streakThreshold // ignore: cast_nullable_to_non_nullable
as int,reminderMode: null == reminderMode ? _self.reminderMode : reminderMode // ignore: cast_nullable_to_non_nullable
as ReminderMode,preOn: null == preOn ? _self.preOn : preOn // ignore: cast_nullable_to_non_nullable
as bool,atOn: null == atOn ? _self.atOn : atOn // ignore: cast_nullable_to_non_nullable
as bool,eodOn: null == eodOn ? _self.eodOn : eodOn // ignore: cast_nullable_to_non_nullable
as bool,riskOn: null == riskOn ? _self.riskOn : riskOn // ignore: cast_nullable_to_non_nullable
as bool,preMin: null == preMin ? _self.preMin : preMin // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
