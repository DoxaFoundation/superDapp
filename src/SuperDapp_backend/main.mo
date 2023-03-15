import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Map "mo:base/HashMap";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";

actor Messap {

  type User = {
    username : Text;
    profilePic : Text;
    coverPic : Text;
    createdAt : Int;
  };

  type Message = {
    sender : Principal;
    receiver : Principal;
    content : Text;
    timeStamp : Int;
  };

  //Hash.hash is depreciated. so this is the walkaround
  private func natHash(n : Nat) : Hash.Hash {
    Text.hash(Nat.toText(n));
  };

  //users HashMap
  let users = Map.HashMap<Principal, User>(1, Principal.equal, Principal.hash);

  //message HashMap
  let messages = Map.HashMap<Nat, Message>(1, Nat.equal, natHash);
  var id : Nat = 0;

  //friends HashMap
  let friends = Map.HashMap<Principal, [Principal]>(
    1,
    Principal.equal,
    Principal.hash,
  );



  //get principal
  //for testing purposes
  public shared(msg) func getP() : async Principal {
    msg.caller;
  };



  //add user
  public shared(msg) func addUser(
    _username : Text,
    _profilePic : Text,
    _coverPic : Text,
  ) : async Text {

    if (users.get(msg.caller) == null) {
      let newUser : User = {
        username = _username;
        profilePic = _profilePic;
        coverPic = _coverPic;
        createdAt = Time.now();
      };

      users.put((msg.caller), newUser);

      "user created successfully";
    } else {
      "user already exists";
    };
  };



  //edit profile Details
  public shared(msg) func editUser(updateUser : User) : async Text {

    let updatedUser : User = {
      username = updateUser.username;
      profilePic = updateUser.profilePic;
      coverPic = updateUser.coverPic;
      createdAt = Time.now();
    };

    let user = users.get(msg.caller);
    switch (user) {
      case (null) {
        "user does not exist";
      };
      case (?user) {
        ignore users.replace((msg.caller), updateUser);
        "update successful";
      };
    };

  };



  //check whether two people are friends.
  public func isFriend(friend1 : Principal, friend2 : Principal) : async Bool {
    let myFriends = friends.get(friend1);

    switch (myFriends) {
      case (null) {
        false;
      };
      case (?friends) {
        let ev = Array.find<Principal>(friends, func x = x == friend2);
        switch (ev) {
          case (null) {
            false;
          };
          case (?friend) {
            true;
          };
        };
      };
    };
  };



  // add a friend
  public shared(msg) func addFriend(friend : Principal) : async Text {
    let fr = await isFriend(msg.caller, friend);

    if (fr) {
      "already friends";
    } else if(fr == false) {
      let user1 = Buffer.fromArray<Principal>(Option.get(friends.get(msg.caller), []));

      user1.add(friend);

      // user1 := Array.append(user1, [friend]);
      ignore friends.replace(msg.caller, Buffer.toArray<Principal>(user1));

      var user2 = Buffer.fromArray<Principal>(Option.get(friends.get(friend), []));
      user2.add(msg.caller);
      // user2 := Array.append(user2, [friend]);
      ignore friends.replace(friend, Buffer.toArray<Principal>(user2));

      "Friend added successfully";
    }else{
      "NOt allowed"
    }

  };

  // remove friend
  public shared(msg) func removeFriend(friend : Principal) : async Text {
    let fr = await isFriend(msg.caller, friend);

    if (fr) {

      var myfriends = Option.get<[Principal]>(friends.get(msg.caller), []);

      var newArray = Array.filter<Principal>(
        myfriends,
        func x = (x != friend),
      );
      ignore friends.replace(msg.caller, newArray);

      var myfriends2 = Option.get<[Principal]>(friends.get(friend), []);
      var newArray2 = Array.filter<Principal>(
        myfriends2,
        func x = (x != (msg.caller)),
      );

      ignore friends.replace(msg.caller, newArray2);

      "enemy removed successfully";
    } else {
      "You are not friends";
    }

  };

  //get friends
  public func myFriends(person : Principal) : async ?[Principal] {

    let myFriends = Option.get(friends.get(person), []);
    ?myFriends
  };



  //send message
  public shared(msg) func sendMessage(
    recipient : Principal,
    _message : Text,
  ) : async Text {

    let _isfriend = await isFriend(msg.caller, recipient);
    if (_isfriend) {
      let newMessage : Message = {
        sender = (msg.caller);
        receiver = recipient;
        content = _message;
        timeStamp = Time.now();
      };

      messages.put(id, newMessage);
      id += 1;
      "message sent successfully"

    } else {
      "You cant send a message to that recipient";
    }

  };


  

  //get conversation
  public shared(msg) func getConversation(_user2 : Principal) : async [Message] {
    var conv : [Message] = [];

    let conversation = Iter.toArray(messages.vals());
    if (conversation.size() == 0) {
      conv

    } else {
      for (convers in conversation.vals()) {
        if (convers.sender == (msg.caller) and convers.receiver == _user2) {
          var temp = Buffer.fromArray<Message>(conv);
          temp.add(convers);
          conv := Buffer.toArray<Message>(temp);
          //conv := Array.append(conv, [convers])

        } else if (convers.sender == _user2 and convers.receiver == (msg.caller)) {
          var temp = Buffer.fromArray<Message>(conv);
          temp.add(convers);
          conv := Buffer.toArray<Message>(temp);
          //conv := Array.append(conv, [convers]);
        }

      };
      conv;
    }

  };

};
