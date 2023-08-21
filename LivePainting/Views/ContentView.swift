//
//  ContentView.swift
//  LivePainting
//
//  Created by rouzbeh on 21.08.23.
//

import SwiftUI

struct ContentView: View {
    @State var scale = 0.0
    @State var name = ""
    @State var shouldNavigate = false
    var body: some View {
        NavigationStack {
            ZStack {
                Image("artBackground")
                VStack {
                    Spacer()
                    Text("What's your name?").foregroundColor(.white).shadow(color: .red,radius: 12).font(.largeTitle)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color.white.opacity(0.8))
                            .frame(height: 50) // Set the desired height
                        
                        TextField("Input name", text: $name)
                            .padding(.leading, 10) // Add padding to adjust text position
                    }.frame(width: 300)
                    
                    Button {
                        shouldNavigate = true
                    } label: {
                        Text("Enter").foregroundColor(.white).frame(maxWidth: 220, maxHeight: 40).background(Color.pink).cornerRadius(10).shadow(radius: 4).bold().opacity(name.isEmpty ? 0: 1.0).animation(.easeIn(duration: 1), value: name)
                    }.padding(.top)
                    Spacer()
                    
                }.scaleEffect(scale).onAppear {
                    withAnimation(.easeInOut(duration: 1)) {
                        scale = 1.0
                    }
                }.padding()
            }.navigationDestination(isPresented: $shouldNavigate, destination: {
                DrawingView(name: name)
            }).ignoresSafeArea()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
