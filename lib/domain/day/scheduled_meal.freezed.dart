// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheduled_meal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScheduledMeal {

 String get id; MealTime get time; DateTime? get skippedAt; DateTime? get snoozedUntil; MealSnapshot get meal;
/// Create a copy of ScheduledMeal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledMealCopyWith<ScheduledMeal> get copyWith => _$ScheduledMealCopyWithImpl<ScheduledMeal>(this as ScheduledMeal, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledMeal&&(identical(other.id, id) || other.id == id)&&(identical(other.time, time) || other.time == time)&&(identical(other.skippedAt, skippedAt) || other.skippedAt == skippedAt)&&(identical(other.snoozedUntil, snoozedUntil) || other.snoozedUntil == snoozedUntil)&&(identical(other.meal, meal) || other.meal == meal));
}


@override
int get hashCode => Object.hash(runtimeType,id,time,skippedAt,snoozedUntil,meal);

@override
String toString() {
  return 'ScheduledMeal(id: $id, time: $time, skippedAt: $skippedAt, snoozedUntil: $snoozedUntil, meal: $meal)';
}


}

/// @nodoc
abstract mixin class $ScheduledMealCopyWith<$Res>  {
  factory $ScheduledMealCopyWith(ScheduledMeal value, $Res Function(ScheduledMeal) _then) = _$ScheduledMealCopyWithImpl;
@useResult
$Res call({
 String id, MealTime time, DateTime? skippedAt, DateTime? snoozedUntil, MealSnapshot meal
});


$MealSnapshotCopyWith<$Res> get meal;

}
/// @nodoc
class _$ScheduledMealCopyWithImpl<$Res>
    implements $ScheduledMealCopyWith<$Res> {
  _$ScheduledMealCopyWithImpl(this._self, this._then);

  final ScheduledMeal _self;
  final $Res Function(ScheduledMeal) _then;

/// Create a copy of ScheduledMeal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? time = null,Object? skippedAt = freezed,Object? snoozedUntil = freezed,Object? meal = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as MealTime,skippedAt: freezed == skippedAt ? _self.skippedAt : skippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,snoozedUntil: freezed == snoozedUntil ? _self.snoozedUntil : snoozedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,meal: null == meal ? _self.meal : meal // ignore: cast_nullable_to_non_nullable
as MealSnapshot,
  ));
}
/// Create a copy of ScheduledMeal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MealSnapshotCopyWith<$Res> get meal {
  
  return $MealSnapshotCopyWith<$Res>(_self.meal, (value) {
    return _then(_self.copyWith(meal: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScheduledMeal].
extension ScheduledMealPatterns on ScheduledMeal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledMeal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledMeal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledMeal value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledMeal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledMeal value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledMeal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MealTime time,  DateTime? skippedAt,  DateTime? snoozedUntil,  MealSnapshot meal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledMeal() when $default != null:
return $default(_that.id,_that.time,_that.skippedAt,_that.snoozedUntil,_that.meal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MealTime time,  DateTime? skippedAt,  DateTime? snoozedUntil,  MealSnapshot meal)  $default,) {final _that = this;
switch (_that) {
case _ScheduledMeal():
return $default(_that.id,_that.time,_that.skippedAt,_that.snoozedUntil,_that.meal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MealTime time,  DateTime? skippedAt,  DateTime? snoozedUntil,  MealSnapshot meal)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledMeal() when $default != null:
return $default(_that.id,_that.time,_that.skippedAt,_that.snoozedUntil,_that.meal);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduledMeal extends ScheduledMeal {
   _ScheduledMeal({required this.id, required this.time, this.skippedAt, this.snoozedUntil, required this.meal}): assert(id != "", 'id must not be empty'),assert(skippedAt == null || skippedAt.isUtc, 'skippedAt must be UTC'),assert(snoozedUntil == null || snoozedUntil.isUtc, 'snoozedUntil must be UTC'),super._();
  

@override final  String id;
@override final  MealTime time;
@override final  DateTime? skippedAt;
@override final  DateTime? snoozedUntil;
@override final  MealSnapshot meal;

/// Create a copy of ScheduledMeal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledMealCopyWith<_ScheduledMeal> get copyWith => __$ScheduledMealCopyWithImpl<_ScheduledMeal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledMeal&&(identical(other.id, id) || other.id == id)&&(identical(other.time, time) || other.time == time)&&(identical(other.skippedAt, skippedAt) || other.skippedAt == skippedAt)&&(identical(other.snoozedUntil, snoozedUntil) || other.snoozedUntil == snoozedUntil)&&(identical(other.meal, meal) || other.meal == meal));
}


@override
int get hashCode => Object.hash(runtimeType,id,time,skippedAt,snoozedUntil,meal);

@override
String toString() {
  return 'ScheduledMeal(id: $id, time: $time, skippedAt: $skippedAt, snoozedUntil: $snoozedUntil, meal: $meal)';
}


}

/// @nodoc
abstract mixin class _$ScheduledMealCopyWith<$Res> implements $ScheduledMealCopyWith<$Res> {
  factory _$ScheduledMealCopyWith(_ScheduledMeal value, $Res Function(_ScheduledMeal) _then) = __$ScheduledMealCopyWithImpl;
@override @useResult
$Res call({
 String id, MealTime time, DateTime? skippedAt, DateTime? snoozedUntil, MealSnapshot meal
});


@override $MealSnapshotCopyWith<$Res> get meal;

}
/// @nodoc
class __$ScheduledMealCopyWithImpl<$Res>
    implements _$ScheduledMealCopyWith<$Res> {
  __$ScheduledMealCopyWithImpl(this._self, this._then);

  final _ScheduledMeal _self;
  final $Res Function(_ScheduledMeal) _then;

/// Create a copy of ScheduledMeal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? time = null,Object? skippedAt = freezed,Object? snoozedUntil = freezed,Object? meal = null,}) {
  return _then(_ScheduledMeal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as MealTime,skippedAt: freezed == skippedAt ? _self.skippedAt : skippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,snoozedUntil: freezed == snoozedUntil ? _self.snoozedUntil : snoozedUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,meal: null == meal ? _self.meal : meal // ignore: cast_nullable_to_non_nullable
as MealSnapshot,
  ));
}

/// Create a copy of ScheduledMeal
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MealSnapshotCopyWith<$Res> get meal {
  
  return $MealSnapshotCopyWith<$Res>(_self.meal, (value) {
    return _then(_self.copyWith(meal: value));
  });
}
}

// dart format on
