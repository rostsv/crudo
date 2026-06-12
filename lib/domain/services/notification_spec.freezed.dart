// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_spec.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotificationSpec {

 int get id; NotificationKind get kind; DateTime get fireAt; String get title; String get body; String? get mealId; bool get withActions;
/// Create a copy of NotificationSpec
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationSpecCopyWith<NotificationSpec> get copyWith => _$NotificationSpecCopyWithImpl<NotificationSpec>(this as NotificationSpec, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationSpec&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.fireAt, fireAt) || other.fireAt == fireAt)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.mealId, mealId) || other.mealId == mealId)&&(identical(other.withActions, withActions) || other.withActions == withActions));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,fireAt,title,body,mealId,withActions);

@override
String toString() {
  return 'NotificationSpec(id: $id, kind: $kind, fireAt: $fireAt, title: $title, body: $body, mealId: $mealId, withActions: $withActions)';
}


}

/// @nodoc
abstract mixin class $NotificationSpecCopyWith<$Res>  {
  factory $NotificationSpecCopyWith(NotificationSpec value, $Res Function(NotificationSpec) _then) = _$NotificationSpecCopyWithImpl;
@useResult
$Res call({
 int id, NotificationKind kind, DateTime fireAt, String title, String body, String? mealId, bool withActions
});




}
/// @nodoc
class _$NotificationSpecCopyWithImpl<$Res>
    implements $NotificationSpecCopyWith<$Res> {
  _$NotificationSpecCopyWithImpl(this._self, this._then);

  final NotificationSpec _self;
  final $Res Function(NotificationSpec) _then;

/// Create a copy of NotificationSpec
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? fireAt = null,Object? title = null,Object? body = null,Object? mealId = freezed,Object? withActions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NotificationKind,fireAt: null == fireAt ? _self.fireAt : fireAt // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,mealId: freezed == mealId ? _self.mealId : mealId // ignore: cast_nullable_to_non_nullable
as String?,withActions: null == withActions ? _self.withActions : withActions // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationSpec].
extension NotificationSpecPatterns on NotificationSpec {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationSpec value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationSpec() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationSpec value)  $default,){
final _that = this;
switch (_that) {
case _NotificationSpec():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationSpec value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationSpec() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  NotificationKind kind,  DateTime fireAt,  String title,  String body,  String? mealId,  bool withActions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationSpec() when $default != null:
return $default(_that.id,_that.kind,_that.fireAt,_that.title,_that.body,_that.mealId,_that.withActions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  NotificationKind kind,  DateTime fireAt,  String title,  String body,  String? mealId,  bool withActions)  $default,) {final _that = this;
switch (_that) {
case _NotificationSpec():
return $default(_that.id,_that.kind,_that.fireAt,_that.title,_that.body,_that.mealId,_that.withActions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  NotificationKind kind,  DateTime fireAt,  String title,  String body,  String? mealId,  bool withActions)?  $default,) {final _that = this;
switch (_that) {
case _NotificationSpec() when $default != null:
return $default(_that.id,_that.kind,_that.fireAt,_that.title,_that.body,_that.mealId,_that.withActions);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationSpec extends NotificationSpec {
   _NotificationSpec({required this.id, required this.kind, required this.fireAt, required this.title, required this.body, this.mealId, this.withActions = false}): assert(fireAt.isUtc, 'fireAt must be UTC'),super._();
  

@override final  int id;
@override final  NotificationKind kind;
@override final  DateTime fireAt;
@override final  String title;
@override final  String body;
@override final  String? mealId;
@override@JsonKey() final  bool withActions;

/// Create a copy of NotificationSpec
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationSpecCopyWith<_NotificationSpec> get copyWith => __$NotificationSpecCopyWithImpl<_NotificationSpec>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationSpec&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.fireAt, fireAt) || other.fireAt == fireAt)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.mealId, mealId) || other.mealId == mealId)&&(identical(other.withActions, withActions) || other.withActions == withActions));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,fireAt,title,body,mealId,withActions);

@override
String toString() {
  return 'NotificationSpec(id: $id, kind: $kind, fireAt: $fireAt, title: $title, body: $body, mealId: $mealId, withActions: $withActions)';
}


}

/// @nodoc
abstract mixin class _$NotificationSpecCopyWith<$Res> implements $NotificationSpecCopyWith<$Res> {
  factory _$NotificationSpecCopyWith(_NotificationSpec value, $Res Function(_NotificationSpec) _then) = __$NotificationSpecCopyWithImpl;
@override @useResult
$Res call({
 int id, NotificationKind kind, DateTime fireAt, String title, String body, String? mealId, bool withActions
});




}
/// @nodoc
class __$NotificationSpecCopyWithImpl<$Res>
    implements _$NotificationSpecCopyWith<$Res> {
  __$NotificationSpecCopyWithImpl(this._self, this._then);

  final _NotificationSpec _self;
  final $Res Function(_NotificationSpec) _then;

/// Create a copy of NotificationSpec
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? fireAt = null,Object? title = null,Object? body = null,Object? mealId = freezed,Object? withActions = null,}) {
  return _then(_NotificationSpec(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as NotificationKind,fireAt: null == fireAt ? _self.fireAt : fireAt // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,mealId: freezed == mealId ? _self.mealId : mealId // ignore: cast_nullable_to_non_nullable
as String?,withActions: null == withActions ? _self.withActions : withActions // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
