//
//  DrawingView.swift
//  LivePainting
//
//  Created by rouzbeh on 21.08.23.
//

import SwiftUI


struct DrawingView: View {

    @ObservedObject var model = MultipeerService()
    @State private var lines: [Line] = []
    var name: String
    @State private var selectedColor: CodableColor = .init(.red)
    @State var selectedIndex = 0
    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    var colors: [CodableColor] = [.init(.red), .init(.green), .init(.blue), .init(.yellow), .init(.orange), .init(.brown), .init(.purple), .init(.black)]
    var body: some View {
        VStack(spacing: 0) {
            HStack() {
                Spacer()
                ForEach(colors.indices, id: \.self) { index in
                    Image(systemName: "pencil.tip").resizable().frame(width: 30, height: 30).foregroundColor(colors[index].swiftUIColor).onTapGesture {
                        selectedIndex = index
                        selectedColor = colors[index]
                    }.offset(y: selectedIndex == index ? -8: 0).shadow(color: .white, radius: index == colors.count - 1 ? 2: 0)
                }
                Spacer()
                clearButton()
                Spacer()
            }.padding(.top).background(Color.black)
            Color.red.frame(maxHeight: 2)
            VStack(alignment: .leading) {
                Text("People in the room:").font(.title).foregroundColor(.white)
                LazyHGrid(rows: columns) {
                    ForEach(Array(model.peerData.connectedDevices), id: \.self) { value in
                        ZStack() {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(Color.black.opacity(0.8)).cornerRadius(10).shadow(color: .white,radius: 2)
                                .frame(width: 80,height: 50).cornerRadius(10) // Set the desired height
                            VStack(alignment: .center) {
                                Text("\(value)").font(.subheadline).foregroundColor(.white)
                                Circle().fill( .green).frame(width: 8, height: 8)
                            }
                        }.padding(.bottom)

                        
                    }
                }.background(.clear)
                
            }.frame(maxWidth: .infinity,maxHeight: 110).background(.black)
            Canvas {ctx, size in
                for line in model.peerData.lines {
                    var path = Path()
                    path.addLines(line.points)
                    ctx.stroke(path, with: .color(line.color.swiftUIColor), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged({ value in
                        let position = value.location
                        if value.translation == .zero {
                            model.peerData.lines.append(Line(points: [position], color: selectedColor))
                         
                        } else {
                            guard let lastIdx = model.peerData.lines.indices.last else {
                                return
                            }
                            model.peerData.lines[lastIdx].points.append(position)
                        }
                        model.sendLines()
                    })
            )
        }.onAppear {
            model.setupPeerWithDisplayName(displayName: name)
        }
    }

    
    @ViewBuilder
    func clearButton() -> some View {
        Button {
            if !model.peerData.lines.isEmpty {
                model.peerData.lines.removeLast()
                model.sendLines()
            }
        } label: {
            Image(systemName: "pencil.tip.crop.circle.badge.minus")
                .font(.largeTitle)
                .foregroundColor(.gray)
        }
    }
}

