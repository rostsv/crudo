// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_ref.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FoodRef {

 String get foodId; Grams get grams;
/// Create a copy of FoodRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodRefCopyWith<FoodRef> get copyWith => _$FoodRefCopyWithImpl<FoodRef>(this as FoodRef, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodRef&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.grams, grams) || other.grams == grams));
}


@override
int get hashCode => Object.hash(runtimeType,foodId,grams);

@override
String toString() {
  return 'FoodRef(foodId: $foodId, grams: $grams)';
}


}

/// @nodoc
abstract mixin class $FoodRefCopyWith<$Res>  {
  factory $FoodRefCopyWith(FoodRef value, $Res Function(FoodRef) _then) = _$FoodRefCopyWithImpl;
@useResult
$Res call({
 String foodId, Grams grams
});




}
/// @nodoc
class _$FoodRefCopyWithImpl<$Res>
    implements $FoodRefCopyWith<$Res> {
  _$FoodRefCopyWithImpl(this._self, this._then);

  final FoodRef _self;
  final $Res Function(FoodRef) _then;

/// Create a copy of FoodRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? foodId = null,Object? grams = null,}) {
  return _then(_self.copyWith(
foodId: null == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as Grams,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodRef].
extension FoodRefPatterns on FoodRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodRef value)  $default,){
final _that = this;
switch (_that) {
case _FoodRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodRef value)?  $default,){
final _that = this;
switch (_that) {
case _FoodRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String foodId,  Grams grams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodRef() when $default != null:
return $default(_that.foodId,_that.grams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String foodId,  Grams grams)  $default,) {final _that = this;
switch (_that) {
case _FoodRef():
return $default(_that.foodId,_that.grams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String foodId,  Grams grams)?  $default,) {final _that = this;
switch (_that) {
case _FoodRef() when $default != null:
return $default(_that.foodId,_that.grams);case _:
  return null;

}
}

}

/// @nodoc


class _FoodRef extends FoodRef {
  const _FoodRef({required this.foodId, required this.grams}): super._();
  

@override final  String foodId;
@override final  Grams grams;

/// Create a copy of FoodRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodRefCopyWith<_FoodRef> get copyWith => __$FoodRefCopyWithImpl<_FoodRef>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodRef&&(identical(other.foodId, foodId) || other.foodId == foodId)&&(identical(other.grams, grams) || other.grams == grams));
}


@override
int get hashCode => Object.hash(runtimeType,foodId,grams);

@override
String toString() {
  return 'FoodRef(foodId: $foodId, grams: $grams)';
}


}

/// @nodoc
abstract mixin class _$FoodRefCopyWith<$Res> implements $FoodRefCopyWith<$Res> {
  factory _$FoodRefCopyWith(_FoodRef value, $Res Function(_FoodRef) _then) = __$FoodRefCopyWithImpl;
@override @useResult
$Res call({
 String foodId, Grams grams
});




}
/// @nodoc
class __$FoodRefCopyWithImpl<$Res>
    implements _$FoodRefCopyWith<$Res> {
  __$FoodRefCopyWithImpl(this._self, this._then);

  final _FoodRef _self;
  final $Res Function(_FoodRef) _then;

/// Create a copy of FoodRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? foodId = null,Object? grams = null,}) {
  return _then(_FoodRef(
foodId: null == foodId ? _self.foodId : foodId // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as Grams,
  ));
}


}

// dart format on
