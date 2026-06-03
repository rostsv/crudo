// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'streak.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Streak {

 int get current; int get personalBest; DateTime? get lastCountedDay;
/// Create a copy of Streak
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreakCopyWith<Streak> get copyWith => _$StreakCopyWithImpl<Streak>(this as Streak, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Streak&&(identical(other.current, current) || other.current == current)&&(identical(other.personalBest, personalBest) || other.personalBest == personalBest)&&(identical(other.lastCountedDay, lastCountedDay) || other.lastCountedDay == lastCountedDay));
}


@override
int get hashCode => Object.hash(runtimeType,current,personalBest,lastCountedDay);

@override
String toString() {
  return 'Streak(current: $current, personalBest: $personalBest, lastCountedDay: $lastCountedDay)';
}


}

/// @nodoc
abstract mixin class $StreakCopyWith<$Res>  {
  factory $StreakCopyWith(Streak value, $Res Function(Streak) _then) = _$StreakCopyWithImpl;
@useResult
$Res call({
 int current, int personalBest, DateTime? lastCountedDay
});




}
/// @nodoc
class _$StreakCopyWithImpl<$Res>
    implements $StreakCopyWith<$Res> {
  _$StreakCopyWithImpl(this._self, this._then);

  final Streak _self;
  final $Res Function(Streak) _then;

/// Create a copy of Streak
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? current = null,Object? personalBest = null,Object? lastCountedDay = freezed,}) {
  return _then(_self.copyWith(
current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,personalBest: null == personalBest ? _self.personalBest : personalBest // ignore: cast_nullable_to_non_nullable
as int,lastCountedDay: freezed == lastCountedDay ? _self.lastCountedDay : lastCountedDay // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Streak].
extension StreakPatterns on Streak {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Streak value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Streak() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Streak value)  $default,){
final _that = this;
switch (_that) {
case _Streak():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Streak value)?  $default,){
final _that = this;
switch (_that) {
case _Streak() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int current,  int personalBest,  DateTime? lastCountedDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Streak() when $default != null:
return $default(_that.current,_that.personalBest,_that.lastCountedDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int current,  int personalBest,  DateTime? lastCountedDay)  $default,) {final _that = this;
switch (_that) {
case _Streak():
return $default(_that.current,_that.personalBest,_that.lastCountedDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int current,  int personalBest,  DateTime? lastCountedDay)?  $default,) {final _that = this;
switch (_that) {
case _Streak() when $default != null:
return $default(_that.current,_that.personalBest,_that.lastCountedDay);case _:
  return null;

}
}

}

/// @nodoc


class _Streak extends Streak {
  const _Streak({this.current = 0, this.personalBest = 0, this.lastCountedDay}): assert(current >= 0, 'current must be >= 0'),assert(personalBest >= 0, 'personalBest must be >= 0'),assert(personalBest >= current, 'personalBest cannot be below current'),super._();
  

@override@JsonKey() final  int current;
@override@JsonKey() final  int personalBest;
@override final  DateTime? lastCountedDay;

/// Create a copy of Streak
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreakCopyWith<_Streak> get copyWith => __$StreakCopyWithImpl<_Streak>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Streak&&(identical(other.current, current) || other.current == current)&&(identical(other.personalBest, personalBest) || other.personalBest == personalBest)&&(identical(other.lastCountedDay, lastCountedDay) || other.lastCountedDay == lastCountedDay));
}


@override
int get hashCode => Object.hash(runtimeType,current,personalBest,lastCountedDay);

@override
String toString() {
  return 'Streak(current: $current, personalBest: $personalBest, lastCountedDay: $lastCountedDay)';
}


}

/// @nodoc
abstract mixin class _$StreakCopyWith<$Res> implements $StreakCopyWith<$Res> {
  factory _$StreakCopyWith(_Streak value, $Res Function(_Streak) _then) = __$StreakCopyWithImpl;
@override @useResult
$Res call({
 int current, int personalBest, DateTime? lastCountedDay
});




}
/// @nodoc
class __$StreakCopyWithImpl<$Res>
    implements _$StreakCopyWith<$Res> {
  __$StreakCopyWithImpl(this._self, this._then);

  final _Streak _self;
  final $Res Function(_Streak) _then;

/// Create a copy of Streak
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? current = null,Object? personalBest = null,Object? lastCountedDay = freezed,}) {
  return _then(_Streak(
current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,personalBest: null == personalBest ? _self.personalBest : personalBest // ignore: cast_nullable_to_non_nullable
as int,lastCountedDay: freezed == lastCountedDay ? _self.lastCountedDay : lastCountedDay // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
