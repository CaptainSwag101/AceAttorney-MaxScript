if (heapSize < 200000) then
    heapSize = 2000000 -- allow ~ 40 MB instead of just 7.5 MB. Prevents "Runtime Error: Out of scripter memory"

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
    exponent = (bit.shift (bit.and hf (bit.hexasint "7C00")) -10) as integer - 16
    fraction = bit.and hf (bit.hexasint "03FF")

    if sign == true then sign = 1 else sign = 0

    exponentF = exponent + 127
    outputAsFloat = bit.or (bit.or (bit.shift fraction 13) \
        (bit.shift exponentF 23)) (bit.shift sign 31)
    return bit.intasfloat outputasfloat*2
)

fn readFixedString bstream fixedLen =
(
    local str = ""
    for i = 1 to fixedLen do
    (
        str += bit.intAsChar (ReadByte bstream #unsigned)
    )
    str
)

fn hexAsString hx =
(
    num = (bit.intashex hx) as string
    str = ""
    pos = num.count;for i = 1 to (num.count / 2) do
    (
        str += bit.intaschar (execute ("0x" + (num[(pos - 1)] + num[(pos)])))
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

fseek f 0x6 #seek_set
BoneCount = ReadShort f #unsigned
MeshCount = ReadShort f #unsigned
fseek f 0xc #seek_set
VertexCount = ReadLong f #unsigned
fseek f 0x18 #seek_set
VertSize = ReadLong f
Long05 = ReadLong f
Long06 = ReadLong f
UsedBoneCount = ReadLong f #unsigned
BoneOff = ReadLong f
Print ("Bone Offset @ 0x" + ((bit.intAsHex(ftell f)) as string))
Print (MeshCount as string)
MatCount2 = ReadShort f #unsigned
fseek f 0x30 #seek_set
MatOff = ReadLong f

itemOff = ReadLong f
Print (itemOff as string)

vertOffset = ReadLong f
Print (vertOffset as string)

faceOffset = ReadLong f
Print (faceOffset as string)

Print ("Item Offset @ 0x" + ((bit.intAsHex(ftell f)) as string))

fseek f BoneOff #seek_set
Print ("Bone Start @ 0x" + ((bit.intAsHex(ftell f)) as string))

BNArr = #()
BoneParent = #()

for a = 1 to BoneCount do
(
    boneId = ReadByte f #unsigned
    append BoneParent (ReadByte f #unsigned)
    childId = ReadByte f #unsigned
    unkId = ReadByte f #unsigned
    floata = ReadFloat f
    floatb = ReadFloat f
    bonex  = ReadFloat f
    boney  = ReadFloat f
    bonez  = ReadFloat f
)

Print ("Bone End @ 0x" + ((bit.intAsHex(ftell f)) as string))

for a = 1 to BoneCount do
(
    getPos = ftell f + 64
    fseek f getPos #seek_set
)

for a = 1 to BoneCount do
(
    c11 = ReadFloat f; c12 = ReadFloat f; c13 = ReadFloat f; c14 = ReadFloat f
    c21 = ReadFloat f; c22 = ReadFloat f; c23 = ReadFloat f; c24 = ReadFloat f
    c31 = ReadFloat f; c32 = ReadFloat f; c33 = ReadFloat f; c34 = ReadFloat f
    c41 = ReadFloat f; c42 = ReadFloat f; c43 = ReadFloat f; c44 = ReadFloat f

    tfm = matrix3 [c11,c12,c13] [c21,c22,c23] [c31,c32,c33] ([c41,c42,c43]*100)

    newBone = bonesys.createbone    \
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
Pos = ftell f

BoneMapArray01 = #()
BoneMapArray02 = #()
BoneMapArray03 = #()
BoneMapArray04 = #()
BoneMapArray05 = #()
BoneMapArray06 = #()
BoneMapArray07 = #()
BoneMapArray08 = #()
BoneMapArray09 = #()
BoneMapArray10 = #()

fseek f Pos #seek_set
if UsedBoneCount > 10 then
(
    errorMsg = "Error: Bone Map count is greater than 8! This may occur if the model you are loading is extremely complex. Your model will continue to load, but it is highly recommended that you contact the script author for a fix before continuing, or you may encounter rigging issues. Please provide the MaxScript Listener log and the associated .mod file to Reddit user CaptainSwag101."
    messagebox (errorMsg)
    Print (errorMsg)
    UsedBoneCount = 10
)
if UsedBoneCount == 1 then
(
    UBoneCount = 1
    for i = 1 to UBoneCount do
    (
        BoneMapCount01 = ReadLong f #unsigned
        for i = 1 to BoneMapCount01 do
        (
            BMap01 = (ReadByte f #unsigned + 1)
            append BoneMapArray01 BMap01
        )
        Stride01 = (24 - BoneMapCount01)
        fseek f Stride01 #seek_cur
    )
)
if UsedBoneCount == 2 then
(
    UBoneCount = 1
    for i = 1 to UBoneCount do
    (
        BoneMapCount01 = ReadLong f #unsigned
        for i = 1 to BoneMapCount01 do
        (
            BMap01 = (ReadByte f #unsigned + 1)
            append BoneMapArray01 BMap01
        )
        Stride01 = (24 - BoneMapCount01)
        fseek f Stride01 #seek_cur
        
        BoneMapCount02 = ReadLong f #unsigned
        for i = 1 to BoneMapCount02 do
        (
            BMap02 = (ReadByte f #unsigned + 1)
            append BoneMapArray02 BMap02
        )
        Stride02 = (24 - BoneMapCount02)
        fseek f Stride02 #seek_cur
    )
)
if UsedBoneCount == 3 then
(
    UBoneCount = 1
    for i = 1 to UBoneCount do
    (
        BoneMapCount01 = ReadLong f #unsigned
        for i = 1 to BoneMapCount01 do
        (
            BMap01 = (ReadByte f #unsigned + 1)
            append BoneMapArray01 BMap01
        )
        Stride01 = (24 - BoneMapCount01)
        fseek f Stride01 #seek_cur
        
        BoneMapCount02 = ReadLong f #unsigned
        for i = 1 to BoneMapCount02 do
        (
            BMap02 = (ReadByte f #unsigned + 1)
            append BoneMapArray02 BMap02
        )
        Stride02 = (24 - BoneMapCount02)
        fseek f Stride02 #seek_cur
        
        BoneMapCount03 = ReadLong f #unsigned
        for i = 1 to BoneMapCount03 do
        (
            BMap03 = (ReadByte f #unsigned + 1)
            append BoneMapArray03 BMap03
        )
        Stride03 = (24 - BoneMapCount03)
        fseek f Stride03 #seek_cur
    )
)
if UsedBoneCount == 4 then
(
    UBoneCount = 1
    for i = 1 to UBoneCount do
    (
        BoneMapCount01 = ReadLong f #unsigned
        for i = 1 to BoneMapCount01 do
        (
            BMap01 = (ReadByte f #unsigned + 1)
            append BoneMapArray01 BMap01
        )
        Stride01 = (24 - BoneMapCount01)
        fseek f Stride01 #seek_cur
        
        BoneMapCount02 = ReadLong f #unsigned
        for i = 1 to BoneMapCount02 do
        (
            BMap02 = (ReadByte f #unsigned + 1)
            append BoneMapArray02 BMap02
        )
        Stride02 = (24 - BoneMapCount02)
        fseek f Stride02 #seek_cur
        
        BoneMapCount03 = ReadLong f #unsigned
        for i = 1 to BoneMapCount03 do
        (
            BMap03 = (ReadByte f #unsigned + 1)
            append BoneMapArray03 BMap03
        )
        Stride03 = (24 - BoneMapCount03)
        fseek f Stride03 #seek_cur
        
        BoneMapCount04 = ReadLong f #unsigned
        for i = 1 to BoneMapCount04 do
        (
            BMap04 = (ReadByte f #unsigned + 1)
            append BoneMapArray04 BMap04
        )
        Stride04 = (24 - BoneMapCount04)
        fseek f Stride04 #seek_cur
    )
)
if UsedBoneCount == 5 then
(
    UBoneCount = 1
    for i = 1 to UBoneCount do
    (
        BoneMapCount01 = ReadLong f #unsigned
        for i = 1 to BoneMapCount01 do
        (
            BMap01 = (ReadByte f #unsigned + 1)
            append BoneMapArray01 BMap01
        )
        Stride01 = (24 - BoneMapCount01)
        fseek f Stride01 #seek_cur
        
        BoneMapCount02 = ReadLong f #unsigned
        for i = 1 to BoneMapCount02 do
        (
            BMap02 = (ReadByte f #unsigned + 1)
            append BoneMapArray02 BMap02
        )
        Stride02 = (24 - BoneMapCount02)
        fseek f Stride02 #seek_cur
        
        BoneMapCount03 = ReadLong f #unsigned
        for i = 1 to BoneMapCount03 do
        (
            BMap03 = (ReadByte f #unsigned + 1)
            append BoneMapArray03 BMap03
        )
        Stride03 = (24 - BoneMapCount03)
        fseek f Stride03 #seek_cur
        
        BoneMapCount04 = ReadLong f #unsigned
        for i = 1 to BoneMapCount04 do
        (
            BMap04 = (ReadByte f #unsigned + 1)
            append BoneMapArray04 BMap04
        )
        Stride04 = (24 - BoneMapCount04)
        fseek f Stride04 #seek_cur
        
        BoneMapCount05 = ReadLong f #unsigned
        for i = 1 to BoneMapCount05 do
        (
            BMap05 = (ReadByte f #unsigned + 1)
            append BoneMapArray05 BMap05
        )
        Stride05 = (24 - BoneMapCount05)
        fseek f Stride05 #seek_cur
    )
)
if UsedBoneCount == 6 then
(
    UBoneCount = 1
    for i = 1 to UBoneCount do
    (
        BoneMapCount01 = ReadLong f #unsigned
        for i = 1 to BoneMapCount01 do
        (
            BMap01 = (ReadByte f #unsigned + 1)
            append BoneMapArray01 BMap01
        )
        Stride01 = (24 - BoneMapCount01)
        fseek f Stride01 #seek_cur
        
        BoneMapCount02 = ReadLong f #unsigned
        for i = 1 to BoneMapCount02 do
        (
            BMap02 = (ReadByte f #unsigned + 1)
            append BoneMapArray02 BMap02
        )
        Stride02 = (24 - BoneMapCount02)
        fseek f Stride02 #seek_cur
        
        BoneMapCount03 = ReadLong f #unsigned
        for i = 1 to BoneMapCount03 do
        (
            BMap03 = (ReadByte f #unsigned + 1)
            append BoneMapArray03 BMap03
        )
        Stride03 = (24 - BoneMapCount03)
        fseek f Stride03 #seek_cur
        
        BoneMapCount04 = ReadLong f #unsigned
        for i = 1 to BoneMapCount04 do
        (
            BMap04 = (ReadByte f #unsigned + 1)
            append BoneMapArray04 BMap04
        )
        Stride04 = (24 - BoneMapCount04)
        fseek f Stride04 #seek_cur
        
        BoneMapCount05 = ReadLong f #unsigned
        for i = 1 to BoneMapCount05 do
        (
            BMap05 = (ReadByte f #unsigned + 1)
            append BoneMapArray05 BMap05
        )
        Stride05 = (24 - BoneMapCount05)
        fseek f Stride05 #seek_cur
        
        BoneMapCount06 = ReadLong f #unsigned
        for i = 1 to BoneMapCount06 do
        (
            BMap06 = (ReadByte f #unsigned + 1)
            append BoneMapArray06 BMap06
        )
        Stride06 = (24 - BoneMapCount06)
        fseek f Stride06 #seek_cur
    )
)
if UsedBoneCount == 7 then
(
    UBoneCount = 1
    for i = 1 to UBoneCount do
    (
        BoneMapCount01 = ReadLong f #unsigned
        for i = 1 to BoneMapCount01 do
        (
            BMap01 = (ReadByte f #unsigned + 1)
            append BoneMapArray01 BMap01
        )
        Stride01 = (24 - BoneMapCount01)
        fseek f Stride01 #seek_cur
        
        BoneMapCount02 = ReadLong f #unsigned
        for i = 1 to BoneMapCount02 do
        (
            BMap02 = (ReadByte f #unsigned + 1)
            append BoneMapArray02 BMap02
        )
        Stride02 = (24 - BoneMapCount02)
        fseek f Stride02 #seek_cur
        
        BoneMapCount03 = ReadLong f #unsigned
        for i = 1 to BoneMapCount03 do
        (
            BMap03 = (ReadByte f #unsigned + 1)
            append BoneMapArray03 BMap03
        )
        Stride03 = (24 - BoneMapCount03)
        fseek f Stride03 #seek_cur
        
        BoneMapCount04 = ReadLong f #unsigned
        for i = 1 to BoneMapCount04 do
        (
            BMap04 = (ReadByte f #unsigned + 1)
            append BoneMapArray04 BMap04
        )
        Stride04 = (24 - BoneMapCount04)
        fseek f Stride04 #seek_cur
        
        BoneMapCount05 = ReadLong f #unsigned
        for i = 1 to BoneMapCount05 do
        (
            BMap05 = (ReadByte f #unsigned + 1)
            append BoneMapArray05 BMap05
        )
        Stride05 = (24 - BoneMapCount05)
        fseek f Stride05 #seek_cur
        
        BoneMapCount06 = ReadLong f #unsigned
        for i = 1 to BoneMapCount06 do
        (
            BMap06 = (ReadByte f #unsigned + 1)
            append BoneMapArray06 BMap06
        )
        Stride06 = (24 - BoneMapCount06)
        fseek f Stride06 #seek_cur
        
        BoneMapCount07 = ReadLong f #unsigned
        for i = 1 to BoneMapCount07 do
        (
            BMap07 = (ReadByte f #unsigned + 1)
            append BoneMapArray07 BMap07
        )
        Stride07 = (24 - BoneMapCount07)
        fseek f Stride07 #seek_cur
    )
)
if UsedBoneCount == 8 then
(
    UBoneCount = 1
    for i = 1 to UBoneCount do
    (
        BoneMapCount01 = ReadLong f #unsigned
        for i = 1 to BoneMapCount01 do
        (
            BMap01 = (ReadByte f #unsigned + 1)
            append BoneMapArray01 BMap01
        )
        Stride01 = (24 - BoneMapCount01)
        fseek f Stride01 #seek_cur
        
        BoneMapCount02 = ReadLong f #unsigned
        for i = 1 to BoneMapCount02 do
        (
            BMap02 = (ReadByte f #unsigned + 1)
            append BoneMapArray02 BMap02
        )
        Stride02 = (24 - BoneMapCount02)
        fseek f Stride02 #seek_cur
        
        BoneMapCount03 = ReadLong f #unsigned
        for i = 1 to BoneMapCount03 do
        (
            BMap03 = (ReadByte f #unsigned + 1)
            append BoneMapArray03 BMap03
        )
        Stride03 = (24 - BoneMapCount03)
        fseek f Stride03 #seek_cur
        
        BoneMapCount04 = ReadLong f #unsigned
        for i = 1 to BoneMapCount04 do
        (
            BMap04 = (ReadByte f #unsigned + 1)
            append BoneMapArray04 BMap04
        )
        Stride04 = (24 - BoneMapCount04)
        fseek f Stride04 #seek_cur
        
        BoneMapCount05 = ReadLong f #unsigned
        for i = 1 to BoneMapCount05 do
        (
            BMap05 = (ReadByte f #unsigned + 1)
            append BoneMapArray05 BMap05
        )
        Stride05 = (24 - BoneMapCount05)
        fseek f Stride05 #seek_cur
        
        BoneMapCount06 = ReadLong f #unsigned
        for i = 1 to BoneMapCount06 do
        (
            BMap06 = (ReadByte f #unsigned + 1)
            append BoneMapArray06 BMap06
        )
        Stride06 = (24 - BoneMapCount06)
        fseek f Stride06 #seek_cur
        
        BoneMapCount07 = ReadLong f #unsigned
        for i = 1 to BoneMapCount07 do
        (
            BMap07 = (ReadByte f #unsigned + 1)
            append BoneMapArray07 BMap07
        )
        Stride07 = (24 - BoneMapCount07)
        fseek f Stride07 #seek_cur
        
        BoneMapCount08 = ReadLong f #unsigned
        for i = 1 to BoneMapCount08 do
        (
            BMap08 = (ReadByte f #unsigned + 1)
            append BoneMapArray08 BMap08
        )
        Stride08 = (24 - BoneMapCount08)
        fseek f Stride08 #seek_cur
    )
)
if UsedBoneCount == 9 then
(
    UBoneCount = 1
    for i = 1 to UBoneCount do
    (
        BoneMapCount01 = ReadLong f #unsigned
        for i = 1 to BoneMapCount01 do
        (
            BMap01 = (ReadByte f #unsigned + 1)
            append BoneMapArray01 BMap01
        )
        Stride01 = (24 - BoneMapCount01)
        fseek f Stride01 #seek_cur
        
        BoneMapCount02 = ReadLong f #unsigned
        for i = 1 to BoneMapCount02 do
        (
            BMap02 = (ReadByte f #unsigned + 1)
            append BoneMapArray02 BMap02
        )
        Stride02 = (24 - BoneMapCount02)
        fseek f Stride02 #seek_cur
        
        BoneMapCount03 = ReadLong f #unsigned
        for i = 1 to BoneMapCount03 do
        (
            BMap03 = (ReadByte f #unsigned + 1)
            append BoneMapArray03 BMap03
        )
        Stride03 = (24 - BoneMapCount03)
        fseek f Stride03 #seek_cur
        
        BoneMapCount04 = ReadLong f #unsigned
        for i = 1 to BoneMapCount04 do
        (
            BMap04 = (ReadByte f #unsigned + 1)
            append BoneMapArray04 BMap04
        )
        Stride04 = (24 - BoneMapCount04)
        fseek f Stride04 #seek_cur
        
        BoneMapCount05 = ReadLong f #unsigned
        for i = 1 to BoneMapCount05 do
        (
            BMap05 = (ReadByte f #unsigned + 1)
            append BoneMapArray05 BMap05
        )
        Stride05 = (24 - BoneMapCount05)
        fseek f Stride05 #seek_cur
        
        BoneMapCount06 = ReadLong f #unsigned
        for i = 1 to BoneMapCount06 do
        (
            BMap06 = (ReadByte f #unsigned + 1)
            append BoneMapArray06 BMap06
        )
        Stride06 = (24 - BoneMapCount06)
        fseek f Stride06 #seek_cur
        
        BoneMapCount07 = ReadLong f #unsigned
        for i = 1 to BoneMapCount07 do
        (
            BMap07 = (ReadByte f #unsigned + 1)
            append BoneMapArray07 BMap07
        )
        Stride07 = (24 - BoneMapCount07)
        fseek f Stride07 #seek_cur
        
        BoneMapCount08 = ReadLong f #unsigned
        for i = 1 to BoneMapCount08 do
        (
            BMap08 = (ReadByte f #unsigned + 1)
            append BoneMapArray08 BMap08
        )
        Stride08 = (24 - BoneMapCount08)
        fseek f Stride08 #seek_cur
        
        BoneMapCount09 = ReadLong f #unsigned
        for i = 1 to BoneMapCount09 do
        (
            BMap09 = (ReadByte f #unsigned + 1)
            append BoneMapArray09 BMap09
        )
        Stride09 = (24 - BoneMapCount09)
        fseek f Stride09 #seek_cur
    )
)
if UsedBoneCount == 10 then
(
    UBoneCount = 1
    for i = 1 to UBoneCount do
    (
        BoneMapCount01 = ReadLong f #unsigned
        for i = 1 to BoneMapCount01 do
        (
            BMap01 = (ReadByte f #unsigned + 1)
            append BoneMapArray01 BMap01
        )
        Stride01 = (24 - BoneMapCount01)
        fseek f Stride01 #seek_cur
        
        BoneMapCount02 = ReadLong f #unsigned
        for i = 1 to BoneMapCount02 do
        (
            BMap02 = (ReadByte f #unsigned + 1)
            append BoneMapArray02 BMap02
        )
        Stride02 = (24 - BoneMapCount02)
        fseek f Stride02 #seek_cur
        
        BoneMapCount03 = ReadLong f #unsigned
        for i = 1 to BoneMapCount03 do
        (
            BMap03 = (ReadByte f #unsigned + 1)
            append BoneMapArray03 BMap03
        )
        Stride03 = (24 - BoneMapCount03)
        fseek f Stride03 #seek_cur
        
        BoneMapCount04 = ReadLong f #unsigned
        for i = 1 to BoneMapCount04 do
        (
            BMap04 = (ReadByte f #unsigned + 1)
            append BoneMapArray04 BMap04
        )
        Stride04 = (24 - BoneMapCount04)
        fseek f Stride04 #seek_cur
        
        BoneMapCount05 = ReadLong f #unsigned
        for i = 1 to BoneMapCount05 do
        (
            BMap05 = (ReadByte f #unsigned + 1)
            append BoneMapArray05 BMap05
        )
        Stride05 = (24 - BoneMapCount05)
        fseek f Stride05 #seek_cur
        
        BoneMapCount06 = ReadLong f #unsigned
        for i = 1 to BoneMapCount06 do
        (
            BMap06 = (ReadByte f #unsigned + 1)
            append BoneMapArray06 BMap06
        )
        Stride06 = (24 - BoneMapCount06)
        fseek f Stride06 #seek_cur
        
        BoneMapCount07 = ReadLong f #unsigned
        for i = 1 to BoneMapCount07 do
        (
            BMap07 = (ReadByte f #unsigned + 1)
            append BoneMapArray07 BMap07
        )
        Stride07 = (24 - BoneMapCount07)
        fseek f Stride07 #seek_cur
        
        BoneMapCount08 = ReadLong f #unsigned
        for i = 1 to BoneMapCount08 do
        (
            BMap08 = (ReadByte f #unsigned + 1)
            append BoneMapArray08 BMap08
        )
        Stride08 = (24 - BoneMapCount08)
        fseek f Stride08 #seek_cur
        
        BoneMapCount09 = ReadLong f #unsigned
        for i = 1 to BoneMapCount09 do
        (
            BMap09 = (ReadByte f #unsigned + 1)
            append BoneMapArray09 BMap09
        )
        Stride09 = (24 - BoneMapCount09)
        fseek f Stride09 #seek_cur
        
        BoneMapCount10 = ReadLong f #unsigned
        for i = 1 to BoneMapCount10 do
        (
            BMap10 = (ReadByte f #unsigned + 1)
            append BoneMapArray10 BMap10
        )
        Stride10 = (24 - BoneMapCount10)
        fseek f Stride10 #seek_cur
    )
)
Print ("Bone Map End @ 0x" + ((bit.intAsHex(ftell f)) as string))

Mesh_Info = #()

fseek f itemOff #seek_set
Print ("Item Start @ 0x" + ((bit.intAsHex(ftell f)) as string))

for i = 1 to MeshCount do
(
    getPos = ftell f + 48
    unk1 = ReadShort f
    vertCount = ReadShort f #unsigned
    unk2 = ReadLong f
    unk3 = ReadShort f
    vSize = ReadByte f
    vType = ReadByte f
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

    fseek f vertOffset #seek_set
    Print ("Vertex Start @ 0x" + ((bit.intAsHex(ftell f)) as string))

    if  (Mesh_Info[i].VSize) == 24 do
    (
        for x = 1 to Mesh_Info[i].VertCount do
        (
            getPos = ftell f + 24

            vx = Readfloat f
            vy = Readfloat f
            vz = Readfloat f

            p1 = Readfloat f

            tu= Readfloat f
            tv= Readfloat f * -1

            fseek f getPos #seek_set

            append vertArray ([vx,-vz,vy] * 10)
            append UV_array [tu,tv,0]
        )
    )
    if  (Mesh_Info[i].VSize) == 28 do
    (
        for x = 1 to Mesh_Info[i].VertCount do
        (
            getPos = ftell f + 28

            vx = Readfloat f
            vy = Readfloat f
            vz = Readfloat f

            p1 = Readfloat f

            tu= Readfloat f
            tv= Readfloat f * -1

            bone1 = ReadByte f #unsigned
            bone2 = ReadByte f #unsigned
            weight1 = ReadByte f #unsigned / 255.0
            weight2 = ReadByte f #unsigned / 255.0

            if weight1 == 1 then
                weight2 = 0

            fseek f getPos #seek_set

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
            append vertArray ([vx,-vz,vy] * 100)
            append UV_array [tu,tv,0]
        )
    )
    if  (Mesh_Info[i].VSize) == 32 do
    (
        for x = 1 to Mesh_Info[i].VertCount do
        (
            getPos = ftell f + 32
            
            vx = Readfloat f
            vy = Readfloat f
            vz = Readfloat f

            p1 = Readfloat f

            tu= Readfloat f
            tv= Readfloat f * -1

            bone1 = ReadByte f #unsigned
            bone2 = ReadByte f #unsigned
            weight1 = ReadByte f #unsigned / 255.0
            weight2 = ReadByte f #unsigned / 255.0

            p2 = Readfloat f

            if weight1 == 1 then
                weight2 = 0

            fseek f getPos #seek_set

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
            append vertArray ([vx,-vz,vy] * 100)
            append UV_array [tu,tv,0]
        )
    )
    if  (Mesh_Info[i].VSize) == 36 do
    (
        for x = 1 to Mesh_Info[i].VertCount do
        (
            vx = Readfloat f
            vy = Readfloat f
            vz = Readfloat f

            unk1 = (ReadShort f / 32767.00)
            unk2 = (ReadShort f / 32767.00)

            tu = Readfloat f
            tv = Readfloat f * -1

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
            append vertArray ([vx,-vz,vy] * 100)
            append UV_array [tu,tv,0]
        )
    )

    if (Mesh_Info[i].VSize) == 44 do
    (
        for x = 1 to Mesh_Info[i].VertCount do
        (
            vx = Readfloat f
            vy = Readfloat f
            vz = Readfloat f

            unk1 = (ReadShort f / 32767.00)
            unk2 = (ReadShort f / 32767.00)

            tu = Readfloat f
            tv = Readfloat f * -1

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
            append vertArray ([vx,-vz,vy] * 100)
            append UV_array [tu,tv,0]
        )
    )

    vertOffset += (Mesh_Info[i].VertCount * Mesh_Info[i].VSize)

    fseek f faceOffset #seek_set
    FaceBuffStart = ftell f
    faceStart = (FaceBuffStart + (Mesh_Info[i].FacePos * 2))

    fseek f (FaceBuffStart + (Mesh_Info[i].FacePos * 2)) #seek_set

    StartDirection = -1
    f1 = (ReadShort f #unsigned + 1) - Mesh_Info[i].VStart
    f2 = (ReadShort f #unsigned + 1) - Mesh_Info[i].VStart
    FaceDirection = StartDirection
    
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
        
        if Mesh_Info[i].MeshId == 1 then
        (
            for c = 1 to BoneMapArray01.count do
            (
                maxbone = BNArr[(BoneMapArray01[c])]
                if c != BoneMapArray01.count then
                    skinOps.addBone skinMod maxbone 0
                else
                    skinOps.addBone skinMod maxbone 1
            )
        )
        if Mesh_Info[i].MeshId == 2 then
        (
            for c = 1 to BoneMapArray02.count do
            (
                maxbone = BNArr[(BoneMapArray02[c])]
                if c != BoneMapArray02.count then
                    skinOps.addBone skinMod maxbone 0
                else
                    skinOps.addBone skinMod maxbone 1
            )
        )
        if Mesh_Info[i].MeshId == 3 then
        (
            for c = 1 to BoneMapArray03.count do
            (
                maxbone = BNArr[(BoneMapArray03[c])]
                if c != BoneMapArray03.count then
                    skinOps.addBone skinMod maxbone 0
                else
                    skinOps.addBone skinMod maxbone 1
            )
        )
        if Mesh_Info[i].MeshId == 4 then
        (
            for c = 1 to BoneMapArray04.count do
            (
                maxbone = BNArr[(BoneMapArray04[c])]
                if c != BoneMapArray04.count then
                    skinOps.addBone skinMod maxbone 0
                else
                    skinOps.addBone skinMod maxbone 1
            )
        )
        if Mesh_Info[i].MeshId == 5 then
        (
            for c = 1 to BoneMapArray05.count do
            (
                maxbone = BNArr[(BoneMapArray05[c])]
                if c != BoneMapArray05.count then
                    skinOps.addBone skinMod maxbone 0
                else
                    skinOps.addBone skinMod maxbone 1
            )
        )
        if Mesh_Info[i].MeshId == 6 then
        (
            for c = 1 to BoneMapArray06.count do
            (
                maxbone = BNArr[(BoneMapArray06[c])]
                if c != BoneMapArray06.count then
                    skinOps.addBone skinMod maxbone 0
                else
                    skinOps.addBone skinMod maxbone 1
            )
        )
        if Mesh_Info[i].MeshId == 7 then
        (
            for c = 1 to BoneMapArray07.count do
            (
                maxbone = BNArr[(BoneMapArray07[c])]
                if c != BoneMapArray07.count then
                    skinOps.addBone skinMod maxbone 0
                else
                    skinOps.addBone skinMod maxbone 1
            )
        )
        if Mesh_Info[i].MeshId == 8 then
        (
            for c = 1 to BoneMapArray08.count do
            (
                maxbone = BNArr[(BoneMapArray08[c])]
                if c != BoneMapArray08.count then
                    skinOps.addBone skinMod maxbone 0
                else
                    skinOps.addBone skinMod maxbone 1
            )
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
    catch
    (
        format "Error!!!\n%\n" (getCurrentException())
    )
    format "Mesh %\n\tMesh Start: %\n\tFace Start: %\n\tVertex Type: %\n\n" i ("0x" + ((bit.intAsHex(vertOffset))as string)) ("0x" + ((bit.intAsHex(faceStart)) as string)) ((((Mesh_Info[i].VType)) as string))
)

fclose f
