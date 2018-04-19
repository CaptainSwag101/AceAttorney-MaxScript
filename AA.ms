fname = getOpenFileName \
caption:"Open .mod from Mesh folder" \
types:"Ace Attorney Model (*.mod)|*.mod" \
historyCategory:"AAObjectPresets"
f = fopen fname "rb"

clearlistener()

fn readHalfFloat fstream =
(
    hf = ReadShort fstream #unsigned
    sign = bit.get hf 16
    exponent = (bit.shift (bit.and hf (bit.hexAsInt "7C00")) -10) as integer - 16
    fraction = bit.and hf (bit.hexAsInt "03FF")

    if sign == true then sign = 1 else sign = 0

    exponentF = exponent + 127
    outputAsFloat = bit.or (bit.or (bit.shift fraction 13) \
        (bit.shift exponentF 23)) (bit.shift sign 31)
    return bit.intAsFloat outputAsFloat * 2
)

fn readFixedString bstream fixedLen =
(
    local str = ""
    for i = 1 to fixedLen do
    (
        str += bit.intAsChar(ReadByte bstream #unsigned)
    )
    str
)

fn hexAsString hx =
(
    num = (bit.intAsHex hx) as string
    str = ""
    pos = num.count
    for i = 1 to (num.count / 2) do
    (
        str += bit.intAsChar ("0x" + (num[(pos - 1)] + num[(pos)]))
        pos -= 2
    )
    str
)

struct weight_data
(
    boneIds, weights
)

struct Mesh_Info_Struct
(
    VertCount, VSize, VType, FacePos, FaceCount, VStart, MeshId
)

clearlistener()

GlobalSizeMultiplier = 100

fseek f 0x06 #seek_set
BoneCount = ReadShort f #unsigned
MeshCount = ReadShort f #unsigned
Print ("Mesh Count: " + (MeshCount as string))
fseek f 0x0C #seek_set
VertCount = ReadLong f #unsigned
fseek f 0x18 #seek_set
VertSize = ReadLong f #unsigned
Long05 = ReadLong f #unsigned
MatCount = ReadLong f #unsigned
UsedBoneCount = ReadLong f #unsigned
BoneOff = ReadLong f #unsigned
Print ("Bone Offset @ 0x" + ((bit.intAsHex(ftell f)) as string))
MatOff = ReadLong f #unsigned
TexOff = ReadLong f #unsigned

ItemOff = ReadLong f #unsigned
Print ("Item Offset @ 0x" + (bit.intAsHex(ItemOff) as string))

VertOff = ReadLong f #unsigned
Print ("Vert Offset @ 0x" + (bit.intAsHex(VertOff) as string))

FaceOff = ReadLong f #unsigned
Print ("Face Offset @ 0x" + (bit.intAsHex(FaceOff) as string))

fseek f BoneOff #seek_set
Print ("Bone Section Start @ 0x" + ((bit.intAsHex(ftell f)) as string))

BNArr = #()
BoneParent = #()

for a = 1 to BoneCount do
(
    boneId  = ReadByte f #unsigned
    append BoneParent (ReadByte f #unsigned)
    childId = ReadByte f #unsigned
    unkId   = ReadByte f #unsigned
    floata  = ReadFloat f
    floatb  = ReadFloat f
    bonex   = ReadFloat f
    boney   = ReadFloat f
    bonez   = ReadFloat f
)

Print ("Bone Data End @ 0x" + ((bit.intAsHex(ftell f)) as string))

for a = 1 to BoneCount do
(
    fseek f 64 #seek_cur
)

for a = 1 to BoneCount do
(
    c11 = ReadFloat f; c12 = ReadFloat f; c13 = ReadFloat f; c14 = ReadFloat f
    c21 = ReadFloat f; c22 = ReadFloat f; c23 = ReadFloat f; c24 = ReadFloat f
    c31 = ReadFloat f; c32 = ReadFloat f; c33 = ReadFloat f; c34 = ReadFloat f
    c41 = ReadFloat f; c42 = ReadFloat f; c43 = ReadFloat f; c44 = ReadFloat f

    tfm = matrix3 [c11,c12,c13] [c21,c22,c23] [c31,c32,c33] ([c41,c42,c43] * GlobalSizeMultiplier)

    newBone = bonesys.createBone    \
            tfm.row4      \
            (tfm.row4 + 0.01 * (normalize tfm.row1)) \
            (normalize tfm.row3)
                        
    newBone.name = (a as string)
    newBone.width  = 0.01
    newBone.height = 0.01
    newBone.transform = inverse tfm
    newBone.setBoneEnable false 0
    newBone.wirecolor = white
    newbone.showlinks = true
    newBone.pos.controller      = TCB_position ()
    newBone.rotation.controller = TCB_rotation ()
    
    if (BoneParent[a] != -1) then
        newBone.parent = BNArr[(BoneParent[a]) + 1]

    append BNArr newBone
)

if BoneCount > 0 then
(
    rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
    for b in BNArr where b.parent == undefined do b.parent = rootRT
    rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
)

fseek f 0x100 #seek_cur
Print ("Bone Section End @ 0x" + ((bit.intAsHex(ftell f)) as string))

BoneMapArrays = #()

for i = 1 to UsedBoneCount do
(
    BoneMapCount = ReadLong f #unsigned
    BMap = #()
    for j = 1 to BoneMapCount do
    (
        val = (ReadByte f #unsigned + 1)
        append BMap val
    )
    append BoneMapArrays BMap
    
    stride = (24 - BoneMapCount)
    fseek f stride #seek_cur
)

Print ("Bone Map End @ 0x" + ((bit.intAsHex(ftell f)) as string))

fseek f TexOff #seek_set
Print ("Texture Start @ 0x" + ((bit.intAsHex(ftell f)) as string))

for i = 1 to MatCount do
(

)

Mesh_Info = #()

fseek f ItemOff #seek_set
Print ("Item Start @ 0x" + ((bit.intAsHex(ftell f)) as string))

for i = 1 to MeshCount do
(
    getPos = ftell f + 48
    unk1 = ReadShort f
    vertCount = ReadShort f #unsigned
    unk2 = ReadLong f
    unk3 = ReadShort f
    vSize = ReadByte f #unsigned
    vType = ReadByte f #unsigned
    vStart = ReadLong f
    unk5 = ReadLong f
    unk6 = ReadLong f
    facePos = ReadLong f
    faceCount = ReadLong f #unsigned
    Null = ReadLong f
    NullB = ReadByte f #unsigned
    meshId = ReadByte f #unsigned + 1
    UBN = ReadByte f #unsigned
    append Mesh_Info (Mesh_Info_Struct VertCount:vertCount VSize:vSize VType:vType FacePos:facePos FaceCount:faceCount VStart:vStart MeshId:meshId)
    fseek f getPos #seek_set
)

Print ("Item End @ 0x" + ((bit.intAsHex(ftell f)) as string))
Print Mesh_Info

for i = 1 to MeshCount do
(
    vertArray = #()
    faceArray = #()
    UV_array = #()
    Weight_array = #()

    fseek f VertOff #seek_set
    Print ("Vertex Start @ 0x" + ((bit.intAsHex(ftell f)) as string))

    if Mesh_Info[i].VSize == 24 then
    (
        for x = 1 to Mesh_Info[i].VertCount do
        (
            vx = ReadFloat f
            vy = ReadFloat f
            vz = ReadFloat f

            p1 = ReadFloat f

            tu = ReadFloat f
            tv = ReadFloat f * -1

            append vertArray ([vx,-vz,vy] / (2.55 * (101 - GlobalSizeMultiplier)))
            append UV_array [tu,tv,0]
        )
    )
    else if Mesh_Info[i].VSize == 28 then
    (
        for x = 1 to Mesh_Info[i].VertCount do
        (
            vx = ReadFloat f
            vy = ReadFloat f
            vz = ReadFloat f

            p1 = ReadFloat f

            tu = ReadFloat f
            tv = ReadFloat f * -1

            bone1 = ReadByte f #unsigned
            bone2 = ReadByte f #unsigned
            weight1 = ReadByte f #unsigned / 255.0
            weight2 = ReadByte f #unsigned / 255.0

            if weight1 == 1 then
                weight2 = 0

            w = (weight_data boneIds:#() weights:#())
            maxweight = 0
            if weight1 != 0 then
                maxweight = maxweight + weight1
            if weight2 != 0 then
                maxweight = maxweight + weight2

            if maxweight != 0 then
            (
                if weight1 != 0 then
                (
                    w1 = weight1 as float
                    append w.boneIds (bone1 + 1)
                    append w.weights (w1)
                )
                if weight2 != 0 then
                (
                    w2 = weight2 as float
                    append w.boneIds (bone2 + 1)
                    append w.weights (w2)
                )
            )
            append Weight_array w
            append vertArray ([vx,-vz,vy] / (2.55 * (101 - GlobalSizeMultiplier)))
            append UV_array [tu,tv,0]
        )
    )
    else if Mesh_Info[i].VSize == 32 then
    (
        for x = 1 to Mesh_Info[i].VertCount do
        (
            vx = ReadFloat f
            vy = ReadFloat f
            vz = ReadFloat f

            p1 = ReadFloat f

            tu = ReadFloat f
            tv = ReadFloat f * -1

            bone1 = ReadByte f #unsigned
            bone2 = ReadByte f #unsigned
            weight1 = ReadByte f #unsigned / 255.0
            weight2 = ReadByte f #unsigned / 255.0

            p2 = ReadFloat f

            if weight1 == 1 then
                weight2 = 0

            w = (weight_data boneIds:#() weights:#())
            maxweight = 0
            if weight1 != 0 then
                maxweight = maxweight + weight1
            if weight2 != 0 then
                maxweight = maxweight + weight2

            if maxweight != 0 then
            (
                if weight1 != 0 then
                (
                    w1 = weight1 as float
                    append w.boneIds (bone1 + 1)
                    append w.weights (w1)
                )
                if weight2 != 0 then
                (
                    w2 = weight2 as float
                    append w.boneIds (bone2 + 1)
                    append w.weights (w2)
                )
            )
            append Weight_array w
            append vertArray ([vx,-vz,vy] * GlobalSizeMultiplier)
            append UV_array [tu,tv,0]
        )
    )
    else if Mesh_Info[i].VSize == 36 then
    (
        for x = 1 to Mesh_Info[i].VertCount do
        (
            vx = ReadFloat f
            vy = ReadFloat f
            vz = ReadFloat f

            unk1 = (ReadShort f / 32767.00)
            unk2 = (ReadShort f / 32767.00)

            tu = ReadFloat f
            tv = ReadFloat f * -1

            bone1 = ReadByte f #unsigned
            bone2 = ReadByte f #unsigned
            weight1 = ReadByte f #unsigned / 255.0
            weight2 = ReadByte f #unsigned / 255.0

            p1 = ReadLong f

            bone3 = ReadByte f #unsigned
            weight3 = ReadByte f #unsigned / 255.0
            bone4 = ReadByte f #unsigned
            weight4 = ReadByte f #unsigned / 255.0

            if weight1 == 1 then
                weight2 = 0
            weight3 = 0
            weight4 = 0

            w = (weight_data boneIds:#() weights:#())
            maxweight = 0
            if weight1 != 0 then
                maxweight = maxweight + weight1
            if weight2 != 0 then
                maxweight = maxweight + weight2
            if weight3 != 0 then
                maxweight = maxweight + weight3
            if weight4 != 0 then
                maxweight = maxweight + weight4

            if maxweight != 0 then
            (
                if weight1 != 0 then
                (
                    w1 = weight1 as float
                    append w.boneIds (bone1 + 1)
                    append w.weights (w1)
                )
                if weight2 != 0 then
                (
                    w2 = weight2 as float
                    append w.boneIds (bone2 + 1)
                    append w.weights (w2)
                )
                if weight3 != 0 then
                (
                    w3 = weight3 as float
                    append w.boneIds (bone3 + 1)
                    append w.weights (w3)
                )
                if weight4 != 0 then
                (
                    w4 = weight4 as float
                    append w.boneIds (bone4 + 1)
                    append w.weights (w4)
                )
            )
            append Weight_array w
            append vertArray ([vx,-vz,vy] * GlobalSizeMultiplier)
            append UV_array [tu,tv,0]
        )
    )
    else if Mesh_Info[i].VSize == 44 then
    (
        for x = 1 to Mesh_Info[i].VertCount do
        (
            vx = ReadFloat f
            vy = ReadFloat f
            vz = ReadFloat f

            unk1 = (ReadShort f / 32767.00)
            unk2 = (ReadShort f / 32767.00)

            tu = ReadFloat f
            tv = ReadFloat f * -1

            bone1 = ReadByte f #unsigned
            bone2 = ReadByte f #unsigned
            weight1 = ReadByte f #unsigned / 255.0
            weight2 = ReadByte f #unsigned / 255.0

            p1 = ReadLong f

            bone3 = ReadByte f #unsigned
            weight3 = ReadByte f #unsigned / 255.0
            bone4 = ReadByte f #unsigned
            weight4 = ReadByte f #unsigned / 255.0

            p2 = ReadLong f
            p3 = ReadLong f

            if weight1 == 1 then
                weight2 = 0
            weight3 = 0
            weight4 = 0

            w = (weight_data boneIds:#() weights:#())
            maxweight = 0
            if weight1 != 0 then
                maxweight = maxweight + weight1
            if weight2 != 0 then
                maxweight = maxweight + weight2
            if weight3 != 0 then
                maxweight = maxweight + weight3
            if weight4 != 0 then
                maxweight = maxweight + weight4

            if maxweight != 0 then
            (
                if weight1 != 0 then
                (
                    w1 = weight1 as float
                    append w.boneIds (bone1 + 1)
                    append w.weights (w1)
                )
                if weight2 != 0 then
                (
                    w2 = weight2 as float
                    append w.boneIds (bone2 + 1)
                    append w.weights (w2)
                )
                if weight3 != 0 then
                (
                    w3 = weight3 as float
                    append w.boneIds (bone3 + 1)
                    append w.weights (w3)
                )
                if weight4 != 0 then
                (
                    w4 = weight4 as float
                    append w.boneIds (bone4 + 1)
                    append w.weights (w4)
                )
            )
            append Weight_array w
            append vertArray ([vx,-vz,vy] * GlobalSizeMultiplier)
            append UV_array [tu,tv,0]
        )
    )
    else
    (
        messageBox("Error, unknown vertex size " + (Mesh_Info[i].VSize as string))
    )

    VertOff += (Mesh_Info[i].VertCount * Mesh_Info[i].VSize)

    faceStart = (FaceOff + (Mesh_Info[i].FacePos * 2))
    fseek f faceStart #seek_set

    StartDirection = -1
    FaceDirection = StartDirection
    f1 = (ReadShort f #unsigned + 1) - Mesh_Info[i].VStart
    f2 = (ReadShort f #unsigned + 1) - Mesh_Info[i].VStart
    
    while (ftell f) < (faceStart + ((Mesh_Info[i].FaceCount) * 2)) do
    (
        f3 = (ReadShort f #unsigned)
        if (f3 == 0xFFFF) then
        (
            f1 = (ReadShort f#unsigned + 1) - Mesh_Info[i].VStart
            f2 = (ReadShort f#unsigned + 1) - Mesh_Info[i].VStart
            FaceDirection = StartDirection
        )
        else
        (
            f3 += (1 - Mesh_Info[i].VStart)
            FaceDirection *= -1
            if (f1 != f2) AND (f2 != f3) AND (f3 != f1) then
            (
                if FaceDirection > 0 then append faceArray [(f1),(f2),(f3)]
                else append faceArray [(f1),(f3),(f2)]
            )
            f1 = f2
            f2 = f3
        )
    )

    Print ("Last Read @ 0x" + ((bit.intAsHex(ftell f)) as string))

    try
    (
        msh = mesh vertices:vertArray faces:faceArray
        msh.numTVerts = UV_array.count
        buildTVFaces msh
        for j = 1 to UV_array.count do setTVert msh j UV_array[j]
        for j = 1 to faceArray.count do setTVFace msh j faceArray[j]
        msh.wirecolor = (color 230 200 210)

        max modify mode
        select msh
        skinMod = skin ()
        addModifier msh skinMod

        if (BoneMapArrays.count > 0) then
        (
            for c = 1 to BoneMapArrays[Mesh_Info[i].MeshId].count do
            (
                maxbone = BNArr[(BoneMapArrays[Mesh_Info[i].MeshId][c])]
                if c != BoneMapArrays[Mesh_Info[i].MeshId].count then
                    skinOps.addBone skinMod maxbone 0
                else
                    skinOps.addBone skinMod maxbone 1
            )
        
            modPanel.setCurrentObject skinMod
            for x = 1 to Mesh_Info[i].VertCount do
            (
                w = Weight_array[x]
                bi = #()
                wv = #()
                
                for j = 1 to w.boneIds.count do
                (
                    boneId = w.boneIds[j]
                    weight = w.weights[j]
                    append bi boneId
                    append wv weight
                )

                skinOps.ReplaceVertexWeights skinMod x bi wv
            )
        )
    )
    catch
    (
        format "Error!!!\n%\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace())
    )
    format "Mesh %\n\tMesh Start: %\n\tFace Start: %\n\tVertex Type: %\n\n" i ("0x" + ((bit.intAsHex(VertOff)) as string)) ("0x" + ((bit.intAsHex(faceStart)) as string)) ((((Mesh_Info[i].VType)) as string))
)

fclose f
