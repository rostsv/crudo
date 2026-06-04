// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MealItem {

 DateTime? get checkedAt; FoodSnapshot get food;
/// Create a copy of MealItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealItemCopyWith<MealItem> get copyWith => _$MealItemCopyWithImpl<MealItem>(this as MealItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealItem&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.food, food) || other.food == food));
}


@override
int get hashCode => Object.hash(runtimeType,checkedAt,food);

@override
String toString() {
  return 'MealItem(checkedAt: $checkedAt, food: $food)';
}


}

/// @nodoc
abstract mixin class $MealItemCopyWith<$Res>  {
  factory $MealItemCopyWith(MealItem value, $Res Function(MealItem) _then) = _$MealItemCopyWithImpl;
@useResult
$Res call({
 DateTime? checkedAt, FoodSnapshot food
});


$FoodSnapshotCopyWith<$Res> get food;

}
/// @nodoc
class _$MealItemCopyWithImpl<$Res>
    implements $MealItemCopyWith<$Res> {
  _$MealItemCopyWithImpl(this._self, this._then);

  final MealItem _self;
  final $Res Function(MealItem) _then;

/// Create a copy of MealItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? checkedAt = freezed,Object? food = null,}) {
  return _then(_self.copyWith(
checkedAt: freezed == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,food: null == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as FoodSnapshot,
  ));
}
/// Create a copy of MealItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodSnapshotCopyWith<$Res> get food {
  
  return $FoodSnapshotCopyWith<$Res>(_self.food, (value) {
    return _then(_self.copyWith(food: value));
  });
}
}


/// Adds pattern-matching-related methods to [MealItem].
extension MealItemPatterns on MealItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealItem value)  $default,){
final _that = this;
switch (_that) {
case _MealItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealItem value)?  $default,){
final _that = this;
switch (_that) {
case _MealItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime? checkedAt,  FoodSnapshot food)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealItem() when $default != null:
return $default(_that.checkedAt,_that.food);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime? checkedAt,  FoodSnapshot food)  $default,) {final _that = this;
switch (_that) {
case _MealItem():
return $default(_that.checkedAt,_that.food);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime? checkedAt,  FoodSnapshot food)?  $default,) {final _that = this;
switch (_that) {
case _MealItem() when $default != null:
return $default(_that.checkedAt,_that.food);case _:
  return null;

}
}

}

/// @nodoc


class _MealItem extends MealItem {
   _MealItem({this.checkedAt, required this.food}): assert(checkedAt == null || checkedAt.isUtc, 'checkedAt must be UTC'),super._();
  

@override final  DateTime? checkedAt;
@override final  FoodSnapshot food;

/// Create a copy of MealItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealItemCopyWith<_MealItem> get copyWith => __$MealItemCopyWithImpl<_MealItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealItem&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt)&&(identical(other.food, food) || other.food == food));
}


@override
int get hashCode => Object.hash(runtimeType,checkedAt,food);

@override
String toString() {
  return 'MealItem(checkedAt: $checkedAt, food: $food)';
}


}

/// @nodoc
abstract mixin class _$MealItemCopyWith<$Res> implements $MealItemCopyWith<$Res> {
  factory _$MealItemCopyWith(_MealItem value, $Res Function(_MealItem) _then) = __$MealItemCopyWithImpl;
@override @useResult
$Res call({
 DateTime? checkedAt, FoodSnapshot food
});


@override $FoodSnapshotCopyWith<$Res> get food;

}
/// @nodoc
class __$MealItemCopyWithImpl<$Res>
    implements _$MealItemCopyWith<$Res> {
  __$MealItemCopyWithImpl(this._self, this._then);

  final _MealItem _self;
  final $Res Function(_MealItem) _then;

/// Create a copy of MealItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? checkedAt = freezed,Object? food = null,}) {
  return _then(_MealItem(
checkedAt: freezed == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,food: null == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as FoodSnapshot,
  ));
}

/// Create a copy of MealItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodSnapshotCopyWith<$Res> get food {
  
  return $FoodSnapshotCopyWith<$Res>(_self.food, (value) {
    return _then(_self.copyWith(food: value));
  });
}
}

// dart format on
