// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlanSlot {

 String get id; String get mealTemplateId; MealTime get time;
/// Create a copy of PlanSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanSlotCopyWith<PlanSlot> get copyWith => _$PlanSlotCopyWithImpl<PlanSlot>(this as PlanSlot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.mealTemplateId, mealTemplateId) || other.mealTemplateId == mealTemplateId)&&(identical(other.time, time) || other.time == time));
}


@override
int get hashCode => Object.hash(runtimeType,id,mealTemplateId,time);

@override
String toString() {
  return 'PlanSlot(id: $id, mealTemplateId: $mealTemplateId, time: $time)';
}


}

/// @nodoc
abstract mixin class $PlanSlotCopyWith<$Res>  {
  factory $PlanSlotCopyWith(PlanSlot value, $Res Function(PlanSlot) _then) = _$PlanSlotCopyWithImpl;
@useResult
$Res call({
 String id, String mealTemplateId, MealTime time
});




}
/// @nodoc
class _$PlanSlotCopyWithImpl<$Res>
    implements $PlanSlotCopyWith<$Res> {
  _$PlanSlotCopyWithImpl(this._self, this._then);

  final PlanSlot _self;
  final $Res Function(PlanSlot) _then;

/// Create a copy of PlanSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? mealTemplateId = null,Object? time = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mealTemplateId: null == mealTemplateId ? _self.mealTemplateId : mealTemplateId // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as MealTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanSlot].
extension PlanSlotPatterns on PlanSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanSlot value)  $default,){
final _that = this;
switch (_that) {
case _PlanSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanSlot value)?  $default,){
final _that = this;
switch (_that) {
case _PlanSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String mealTemplateId,  MealTime time)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanSlot() when $default != null:
return $default(_that.id,_that.mealTemplateId,_that.time);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String mealTemplateId,  MealTime time)  $default,) {final _that = this;
switch (_that) {
case _PlanSlot():
return $default(_that.id,_that.mealTemplateId,_that.time);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String mealTemplateId,  MealTime time)?  $default,) {final _that = this;
switch (_that) {
case _PlanSlot() when $default != null:
return $default(_that.id,_that.mealTemplateId,_that.time);case _:
  return null;

}
}

}

/// @nodoc


class _PlanSlot extends PlanSlot {
  const _PlanSlot({required this.id, required this.mealTemplateId, required this.time}): super._();
  

@override final  String id;
@override final  String mealTemplateId;
@override final  MealTime time;

/// Create a copy of PlanSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanSlotCopyWith<_PlanSlot> get copyWith => __$PlanSlotCopyWithImpl<_PlanSlot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.mealTemplateId, mealTemplateId) || other.mealTemplateId == mealTemplateId)&&(identical(other.time, time) || other.time == time));
}


@override
int get hashCode => Object.hash(runtimeType,id,mealTemplateId,time);

@override
String toString() {
  return 'PlanSlot(id: $id, mealTemplateId: $mealTemplateId, time: $time)';
}


}

/// @nodoc
abstract mixin class _$PlanSlotCopyWith<$Res> implements $PlanSlotCopyWith<$Res> {
  factory _$PlanSlotCopyWith(_PlanSlot value, $Res Function(_PlanSlot) _then) = __$PlanSlotCopyWithImpl;
@override @useResult
$Res call({
 String id, String mealTemplateId, MealTime time
});




}
/// @nodoc
class __$PlanSlotCopyWithImpl<$Res>
    implements _$PlanSlotCopyWith<$Res> {
  __$PlanSlotCopyWithImpl(this._self, this._then);

  final _PlanSlot _self;
  final $Res Function(_PlanSlot) _then;

/// Create a copy of PlanSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? mealTemplateId = null,Object? time = null,}) {
  return _then(_PlanSlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,mealTemplateId: null == mealTemplateId ? _self.mealTemplateId : mealTemplateId // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as MealTime,
  ));
}


}

// dart format on
