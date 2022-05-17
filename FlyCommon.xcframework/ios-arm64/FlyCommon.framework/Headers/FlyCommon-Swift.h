// Generated by Apple Swift version 5.5 (swiftlang-1300.0.31.1 clang-1300.0.29.1)
#ifndef FLYCOMMON_SWIFT_H
#define FLYCOMMON_SWIFT_H
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgcc-compat"

#if !defined(__has_include)
# define __has_include(x) 0
#endif
#if !defined(__has_attribute)
# define __has_attribute(x) 0
#endif
#if !defined(__has_feature)
# define __has_feature(x) 0
#endif
#if !defined(__has_warning)
# define __has_warning(x) 0
#endif

#if __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <Foundation/Foundation.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus)
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...)
# endif
#endif

#if __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if __has_attribute(objc_method_family)
# define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
#else
# define SWIFT_METHOD_FAMILY(X)
#endif
#if __has_attribute(noescape)
# define SWIFT_NOESCAPE __attribute__((noescape))
#else
# define SWIFT_NOESCAPE
#endif
#if __has_attribute(ns_consumed)
# define SWIFT_RELEASES_ARGUMENT __attribute__((ns_consumed))
#else
# define SWIFT_RELEASES_ARGUMENT
#endif
#if __has_attribute(warn_unused_result)
# define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
# define SWIFT_WARN_UNUSED_RESULT
#endif
#if __has_attribute(noreturn)
# define SWIFT_NORETURN __attribute__((noreturn))
#else
# define SWIFT_NORETURN
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif
#if !defined(SWIFT_RESILIENT_CLASS)
# if __has_attribute(objc_class_stub)
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME) __attribute__((objc_class_stub))
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_class_stub)) SWIFT_CLASS_NAMED(SWIFT_NAME)
# else
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME)
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) SWIFT_CLASS_NAMED(SWIFT_NAME)
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM_ATTR)
# if defined(__has_attribute) && __has_attribute(enum_extensibility)
#  define SWIFT_ENUM_ATTR(_extensibility) __attribute__((enum_extensibility(_extensibility)))
# else
#  define SWIFT_ENUM_ATTR(_extensibility)
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name, _extensibility) enum _name : _type _name; enum SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# if __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) SWIFT_ENUM(_type, _name, _extensibility)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_WEAK_IMPORT)
# define SWIFT_WEAK_IMPORT __attribute__((weak_import))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if __has_feature(attribute_diagnose_if_objc)
# define SWIFT_DEPRECATED_OBJC(Msg) __attribute__((diagnose_if(1, Msg, "warning")))
#else
# define SWIFT_DEPRECATED_OBJC(Msg) SWIFT_DEPRECATED_MSG(Msg)
#endif
#if !defined(IBSegueAction)
# define IBSegueAction
#endif
#if __has_feature(modules)
#if __has_warning("-Watimport-in-framework-header")
#pragma clang diagnostic ignored "-Watimport-in-framework-header"
#endif
@import Foundation;
@import ObjectiveC;
#endif

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
#if __has_warning("-Wpragma-clang-attribute")
# pragma clang diagnostic ignored "-Wpragma-clang-attribute"
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wnullability"

#if __has_attribute(external_source_symbol)
# pragma push_macro("any")
# undef any
# pragma clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in="FlyCommon",generated_declaration))), apply_to=any(function,enum,objc_interface,objc_category,objc_protocol))
# pragma pop_macro("any")
#endif


SWIFT_CLASS("_TtC9FlyCommon14CallUsersModel")
@interface CallUsersModel : NSObject
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

@class NSString;
@class NSNumber;
enum MessageStatus : NSInteger;
@class ContactChatMessage;
@class LocationChatMessage;
@class MediaChatMessage;
@class ReplyParentChatMessage;

SWIFT_CLASS("_TtC9FlyCommon11ChatMessage")
@interface ChatMessage : NSObject
/// Unique Id of a ChatMessage
/// Expressed as a random string derived from UUID with - replaced by empty string
@property (nonatomic, copy) NSString * _Nonnull messageId;
/// Text content of the message if it was available
@property (nonatomic, copy) NSString * _Nonnull messageTextContent;
/// Posted time of the message in milliseconds
@property (nonatomic) double messageSentTime;
/// Name of the Chat user if available
@property (nonatomic, copy) NSString * _Nonnull senderUserName;
/// Nick Name of the Chat user if available
@property (nonatomic, copy) NSString * _Nonnull senderNickName;
/// Jid of the Chat user if it is a group
@property (nonatomic, copy) NSString * _Nonnull senderUserJid;
/// Jid of the chat user
@property (nonatomic, copy) NSString * _Nonnull chatUserJid;
/// Status of the message
@property (nonatomic) enum MessageStatus messageStatus;
/// True if message was sent by you
@property (nonatomic) BOOL isMessageSentByMe;
/// True if the message is sent by you from another resource like web/pc
@property (nonatomic) BOOL isCarbonMessage;
/// True if you starred/favourite the message
@property (nonatomic) BOOL isMessageStarred;
/// True if the message was deleted locally
@property (nonatomic) BOOL isMessageDeleted;
/// True if the message was deleted by the sender
@property (nonatomic) BOOL isMessageRecalled;
/// True if the message was translated
@property (nonatomic) BOOL isMessageTranslated;
/// To check whether the contact is saved in our phonebook
@property (nonatomic) BOOL isSavedContact;
/// To check if this is a reply to another message
@property (nonatomic) BOOL isReplyMessage;
/// Translated text will be available here if translated
@property (nonatomic, copy) NSString * _Nonnull translatedMessageTextContent;
/// Holds the contact data if this is a contact message
@property (nonatomic, strong) ContactChatMessage * _Nullable contactChatMessage;
/// Holds the location data if this is a location message
@property (nonatomic, strong) LocationChatMessage * _Nullable locationChatMessage;
/// Holds the media details if this is a media message
@property (nonatomic, strong) MediaChatMessage * _Nullable mediaChatMessage;
/// Hold the necessary data of the original parent message to which this message is a reply
@property (nonatomic, strong) ReplyParentChatMessage * _Nullable replyParentChatMessage;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


SWIFT_CLASS("_TtC9FlyCommon18ContactChatMessage")
@interface ContactChatMessage : NSObject
/// Id of the message
@property (nonatomic, copy) NSString * _Nonnull messageId;
/// Name of the contact
@property (nonatomic, copy) NSString * _Nonnull contactName;
/// Jid of the contact if available
@property (nonatomic, copy) NSString * _Nonnull contactJid;
/// List of phone numbers available for the contact
@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> * _Nonnull contactPhoneNumbers;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


SWIFT_CLASS("_TtC9FlyCommon19FlyCommonController")
@interface FlyCommonController : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end


SWIFT_CLASS("_TtC9FlyCommon16GroupCallDetails")
@interface GroupCallDetails : NSObject
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


SWIFT_CLASS("_TtC9FlyCommon10GroupModel")
@interface GroupModel : NSObject
/// groupId of the group profile
@property (nonatomic, copy) NSString * _Null_unspecified groupId;
/// groupCreatedTime of the group profile
@property (nonatomic, copy) NSString * _Nonnull groupCreatedTime;
/// groupImage of the group profile
@property (nonatomic, copy) NSString * _Nonnull groupImage;
/// groupName of the group profile
@property (nonatomic, copy) NSString * _Nonnull groupName;
/// groupAffiliation of the group profile
@property (nonatomic, copy) NSString * _Nonnull groupAffiliation;
/// groupItemId of the group profile
@property (nonatomic, copy) NSString * _Nonnull groupItemId;
- (nonnull instancetype)initWithGroupId:(NSString * _Nonnull)groupId OBJC_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end

@class ProfileDetails;

SWIFT_CLASS("_TtC9FlyCommon22GroupParticipantDetail")
@interface GroupParticipantDetail : NSObject
/// Jid of the vcard
@property (nonatomic, copy) NSString * _Null_unspecified groupMemberId;
/// Jid of the vcard
@property (nonatomic, copy) NSString * _Null_unspecified groupJid;
/// Name of the vcard
@property (nonatomic, copy) NSString * _Nonnull memberJid;
/// memberItemId of the user
@property (nonatomic, copy) NSString * _Nonnull memberItemId;
/// time of the user
@property (nonatomic, copy) NSString * _Nonnull time;
/// stanzaId of the user
@property (nonatomic, copy) NSString * _Null_unspecified stanzaId;
/// isAdminMember of the user
@property (nonatomic) BOOL isAdminMember;
/// profile dtails of participant
@property (nonatomic, strong) ProfileDetails * _Nullable profileDetail;
- (nonnull instancetype)initWithGroupMemberId:(NSString * _Nonnull)groupMemberId OBJC_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end


SWIFT_CLASS("_TtC9FlyCommon19LocationChatMessage")
@interface LocationChatMessage : NSObject
/// Id of the message
@property (nonatomic, copy) NSString * _Nonnull messageId;
/// Latitude of the location
@property (nonatomic) double latitude;
/// Longitude of the location
@property (nonatomic) double longitude;
/// Url to go to a map for the location
@property (nonatomic, copy) NSString * _Nonnull mapLocationUrl;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


SWIFT_CLASS("_TtC9FlyCommon16MediaChatMessage")
@interface MediaChatMessage : NSObject
/// Id of the message
@property (nonatomic, copy) NSString * _Nonnull messageId;
/// Name of the media file
@property (nonatomic, copy) NSString * _Nonnull mediaFileName;
/// Duration of the media file if its a audio/video
@property (nonatomic) int32_t mediaDuration;
/// Size of the media file
@property (nonatomic) int32_t mediaFileSize;
/// Type of the file
@property (nonatomic, copy) NSString * _Nonnull mediaFileType;
/// server url
@property (nonatomic, copy) NSString * _Nonnull mediaFileUrl;
/// Local path in which the media file resides if its available
@property (nonatomic, copy) NSString * _Nonnull mediaLocalStoragePath;
/// Base64 thumbnail image string if it is a video/image
@property (nonatomic, copy) NSString * _Nonnull mediaThumbImage;
/// Holds the caption if provided
@property (nonatomic, copy) NSString * _Nonnull mediaCaptionText;
/// Progress of the upload/download media file
@property (nonatomic) NSInteger mediaProgressStatus;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

typedef SWIFT_ENUM(NSInteger, MessageStatus, open) {
  MessageStatusNotAcknowledged = 0,
  MessageStatusSent = 1,
  MessageStatusAcknowledged = 2,
  MessageStatusDelivered = 3,
  MessageStatusSeen = 4,
  MessageStatusReceived = 5,
};


SWIFT_CLASS("_TtC9FlyCommon18ParticipantDetails")
@interface ParticipantDetails : NSObject
/// Jid of the admin User
@property (nonatomic, readonly, copy) NSString * _Null_unspecified jid;
/// groupJid of  the  group
@property (nonatomic, copy) NSString * _Nonnull groupJid;
/// stanzaId of  the group
@property (nonatomic, copy) NSString * _Nonnull stanzaId;
/// retractId of  the group
@property (nonatomic, copy) NSString * _Nonnull retractId;
/// removeParticipantJid of  the group
@property (nonatomic, copy) NSString * _Nonnull removeParticipantJid;
/// publisherJid of  the group
@property (nonatomic, copy) NSString * _Nonnull publisherId;
/// removeTime of  the group
@property (nonatomic, copy) NSString * _Nonnull time;
/// image  of  the group
@property (nonatomic, copy) NSString * _Nonnull groupImage;
/// name of  the group
@property (nonatomic, copy) NSString * _Nonnull groupName;
/// adminJid of  the group
@property (nonatomic, copy) NSString * _Nonnull newAdmin;
/// The member ,who made  meember as admin
@property (nonatomic, copy) NSString * _Nonnull doneBy;
- (nonnull instancetype)initWithJid:(NSString * _Nonnull)jid OBJC_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end


SWIFT_CLASS("_TtC9FlyCommon14ProfileDetails")
@interface ProfileDetails : NSObject
/// Jid of the vcard
@property (nonatomic, copy) NSString * _Null_unspecified jid;
/// Name of the vcard
@property (nonatomic, copy) NSString * _Nonnull name;
/// Nickname of the user
@property (nonatomic, copy) NSString * _Nonnull nickName;
/// Image url of the user
@property (nonatomic, copy) NSString * _Nonnull image;
/// Image local  path of the user
@property (nonatomic, copy) NSString * _Nonnull imageLocalPath;
/// Mobile number of the user
@property (nonatomic, copy) NSString * _Nonnull mobileNumber;
/// Status of the user
@property (nonatomic, copy) NSString * _Nonnull status;
/// Mail of the user
@property (nonatomic, copy) NSString * _Nonnull email;
/// Colour code for each user
@property (nonatomic, copy) NSString * _Nonnull colorCode;
/// Image privacy flag
@property (nonatomic) BOOL imagePrivacyFlag;
/// Status privacy flag
@property (nonatomic) BOOL statusPrivacyFlag;
/// Last seen privacy flag
@property (nonatomic) BOOL lastSeenPrivacyFlag;
/// Mobile number privacy flag
@property (nonatomic) BOOL mobileNUmberPrivacyFlag;
/// boolean to represent th mute status for this user
@property (nonatomic) BOOL isMuted;
/// boolean to represent whether we blocked this user
@property (nonatomic) BOOL isBlocked;
/// boolean to represent whether this user blocked us
@property (nonatomic) BOOL isBlockedMe;
/// boolean to represent whether this user is one of the admin of a group
@property (nonatomic) BOOL isGroupAdmin;
/// boolean to check whether the contact is saved in our phonebook
@property (nonatomic) BOOL isItSavedContact;
/// Holds the data of created time of a group
@property (nonatomic) double groupCreatedTime;
/// Checks whether the group was created in server or not
@property (nonatomic) BOOL isGroupInOfflineMode;
/// Property to hold selected value during multi selection
@property (nonatomic) BOOL isSelected;
/// group name  of the participant
@property (nonatomic, copy) NSString * _Null_unspecified nick;
/// itemId of the vcard
@property (nonatomic, copy) NSString * _Null_unspecified itemId;
/// groupAffiliation of the group profile
@property (nonatomic, copy) NSString * _Nullable affiliation;
/// To check whether group sync is needed or not to get participants from server
@property (nonatomic) BOOL isSyncNeeded;
/// To check whether contact is blocked by admin or not
@property (nonatomic) BOOL isBlockedByAdmin;
- (nonnull instancetype)initWithJid:(NSString * _Nonnull)jid OBJC_DESIGNATED_INITIALIZER;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end


SWIFT_CLASS("_TtC9FlyCommon10RecentChat")
@interface RecentChat : NSObject
/// Jid of the user/group/broadcast
@property (nonatomic, copy) NSString * _Nonnull jid;
/// Name of the\is recent chat profile
@property (nonatomic, copy) NSString * _Nonnull nickName;
/// Image url endpoint of this recent chat profile
@property (nonatomic, copy) NSString * _Nonnull profileName;
/// Check whether the entity belongs to a single chat user or a group
@property (nonatomic) BOOL isGroup;
/// Check whether the entity belongs to a single chat user or a broadcast
@property (nonatomic) BOOL isBroadCast;
/// Provides the count of unread message count for this recent chat profile
@property (nonatomic) NSInteger unreadMessageCount;
/// To check whether this recent chat user/group is archived
@property (nonatomic) BOOL isChatArchived;
/// To check whether this recent chat model is a pinned to appear on top
@property (nonatomic) BOOL isChatPinned;
@property (nonatomic, copy) NSString * _Nullable profileImage;
/// Id of the last Message sent/received between us and this recent chat profile
@property (nonatomic, copy) NSString * _Nonnull lastMessageId;
/// Data of the last message(text message | image caption) sent/received between us and the user/group
@property (nonatomic, copy) NSString * _Nonnull lastMessageContent;
/// Time in milliseconds of the last message sent/received between us and the user/group
@property (nonatomic) double lastMessageTime;
/// To check whether the last message is sent by us
@property (nonatomic) BOOL isLastMessageSentByMe;
/// To check whether the last message is deleted by the user for all
@property (nonatomic) BOOL isLastMessageRecalledByUser;
/// To check the mute status for this recent chat profile
@property (nonatomic) BOOL isMuted;
/// To check whether we blocked this recent chat profile
@property (nonatomic) BOOL isBlocked;
/// To check whether this user blocked us
@property (nonatomic) BOOL isBlockedMe;
/// Property to hold selected value during multi selection
@property (nonatomic) BOOL isSelected;
/// To check whether the contact is saved in our phonebook
@property (nonatomic) BOOL isItSavedContact;
/// Checks whether the group was created in server or not
@property (nonatomic) BOOL isGroupInOfflineMode;
/// To check whether the conversation with the user is read or not
@property (nonatomic) BOOL isConversationUnRead;
/// To check if contact blocked by admin or not
@property (nonatomic) BOOL isBlockedByAdmin;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


SWIFT_CLASS("_TtC9FlyCommon22ReplyParentChatMessage")
@interface ReplyParentChatMessage : NSObject
/// Id of the message
@property (nonatomic, copy) NSString * _Nonnull messageId;
/// Jid of the chat user
@property (nonatomic, copy) NSString * _Nonnull chatUserJid;
/// True if message was sent by you
@property (nonatomic) BOOL isMessageSentByMe;
/// Posted time of the message in milliseconds
@property (nonatomic) double messageSentTime;
/// Name of the Chat user if available
@property (nonatomic, copy) NSString * _Nonnull senderUserName;
/// Nick Name of the Chat user if available
@property (nonatomic, copy) NSString * _Nonnull senderNickName;
/// True if you starred/favourite the message
@property (nonatomic) BOOL isMessageStarred;
/// True if the message was deleted locally
@property (nonatomic) BOOL isMessageDeleted;
/// True if the message was deleted by the sender
@property (nonatomic) BOOL isMessageRecalled;
/// Text content of the message if it was available
@property (nonatomic, copy) NSString * _Nonnull messageTextContent;
/// Holds the contact data if this is a contact message
@property (nonatomic, strong) ContactChatMessage * _Nullable contactChatMessage;
/// Holds the location data if this is a location message
@property (nonatomic, strong) LocationChatMessage * _Nullable locationChatMessage;
/// Holds the media details if this is a media message
@property (nonatomic, strong) MediaChatMessage * _Nullable mediaChatMessage;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


#if __has_attribute(external_source_symbol)
# pragma clang attribute pop
#endif
#pragma clang diagnostic pop
#endif
