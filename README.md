# flutter_example_grpc


This Flutter example utilizes gRPC and is created as a demonstration for Cross-Platform Mobile Application Development course.

Dart gRPC Server for the app is found here: https://github.com/MatiasHiltunen/flutter_example_grpc

## Protos

If changes to protos are made in server's proto-file, update the proto-file also in this project to match the same one on the server. This is important as the proto-file needs to be consistent everywhere its used. 


After updating proto-file on protos folder, update generated code with:

```bash
protoc --dart_out=grpc:lib/generated -Iprotos protos/movie_match.proto
```

- Note: requires `protoc` to be installed and available in PATH: https://grpc.io/docs/protoc-installation/





## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
