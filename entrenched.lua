-- language: Lua, file: entrenched_infinite_esp.lua, runtime: Roblox internal (Madium)
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local WS=game:GetService("Workspace")
local LP=Players.LocalPlayer
local Cam=WS.CurrentCamera

getgenv().Entrenched = getgenv().Entrenched or {
    Aim=true, ESP=true,
    Auto=true,
    FOV=380, Smooth=0.14, Pred=0.11,
    HitPart="Head", TeamCheck=true, WallCheck=true,
    ShowFOV=true, Boxes=true, Names=true, Health=true, Tracers=false
}

local holding=false
UIS.InputBegan:Connect(function(i,gp) if gp then return end if i.UserInputType==Enum.UserInputType.MouseButton2 then holding=true end if i.KeyCode==Enum.KeyCode.Q then getgenv().Entrenched.Aim=not getgenv().Entrenched.Aim end if i.KeyCode==Enum.KeyCode.E then getgenv().Entrenched.ESP=not getgenv().Entrenched.ESP end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then holding=false end end)

local fov=Drawing.new("Circle"); fov.Thickness=1.6; fov.NumSides=64; fov.Filled=false; fov.Transparency=0.75
RS.RenderStepped:Connect(function() fov.Visible=getgenv().Entrenched.ShowFOV and getgenv().Entrenched.Aim; fov.Radius=getgenv().Entrenched.FOV/2; fov.Position=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2); fov.Color=(getgenv().Entrenched.Auto or holding) and Color3.fromRGB(88,101,242) or Color3.fromRGB(120,140,255) end)

local function alive(p) local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid"); return h and h.Health>0 end

local function isLeaf(part)
    if not part then return false end
    local n=part.Name:lower()
    if n:find("leaf") or n:find("leaves") or n:find("foliage") or n:find("bush") or n:find("grass") or n:find("fern") then return true end
    if part.Transparency > 0.35 then return true end
    if not part.CanCollide then return true end
    if part.Material == Enum.Material.Grass or part.Material == Enum.Material.Leaf then return true end
    local p=part.Parent
    if p and (p.Name:lower():find("foliage") or p.Name:lower():find("leaf") or p.Name:lower():find("tree")) then return true end
    return false
end

local function visible(part)
    if not getgenv().Entrenched.WallCheck then return true end
    local o=Cam.CFrame.Position; local dir=part.Position - o
    local pr=RaycastParams.new()
    pr.FilterDescendantsInstances={LP.Character, part.Parent}
    pr.FilterType=Enum.RaycastFilterType.Exclude
    local res=WS:Raycast(o, dir, pr)
    if not res then return true end
    if isLeaf(res.Instance) then return true end
    local pr2=RaycastParams.new()
    pr2.FilterDescendantsInstances={LP.Character, part.Parent, res.Instance}
    pr2.FilterType=Enum.RaycastFilterType.Exclude
    local res2=WS:Raycast(o, dir, pr2)
    if res2 and isLeaf(res2.Instance) then return true end
    if res2 then return false end
    return false
end

local function getClosest()
    local center=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
    local best,bestD,bestP=nil,getgenv().Entrenched.FOV/2,nil
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and alive(p) and p.Character then
            if getgenv().Entrenched.TeamCheck and p.Team==LP.Team then continue end
            local part=p.Character:FindFirstChild(getgenv().Entrenched.HitPart) or p.Character:FindFirstChild("Head") or p.Character:FindFirstChild("HumanoidRootPart")
            if not part then continue end
            if not visible(part) then continue end
            local pred=part.Position + part.Velocity*getgenv().Entrenched.Pred
            local pos,on=Cam:WorldToViewportPoint(pred)
            if not on then continue end
            local d=(Vector2.new(pos.X,pos.Y)-center).Magnitude
            if d<bestD then bestD=d; best=p; bestP=part end
        end
    end
    return best,bestP
end

RS.RenderStepped:Connect(function()
    if not getgenv().Entrenched.Aim then return end
    if not getgenv().Entrenched.Auto and not holding then return end
    local _,part=getClosest()
    if part then
        local pred=part.Position + part.Velocity*getgenv().Entrenched.Pred
        local goal=CFrame.lookAt(Cam.CFrame.Position, pred)
        Cam.CFrame=Cam.CFrame:Lerp(goal, 1 - getgenv().Entrenched.Smooth)
    end
end)

local cache={}
local function newD(t,p) local d=Drawing.new(t); for k,v in pairs(p) do d[k]=v end return d end
local function add(p) if p==LP or cache[p] then return end cache[p]={Box=newD("Square",{Thickness=1.6,Filled=false,Visible=false}),Fill=newD("Square",{Filled=true,Transparency=0.12,Visible=false}),Name=newD("Text",{Center=true,Outline=true,OutlineColor=Color3.new(0,0,0),Size=12,Visible=false,Font=2}),HPBg=newD("Line",{Thickness=4,Transparency=0.5,Visible=false,Color=Color3.new(0,0,0)}),HP=newD("Line",{Thickness=3,Visible=false}),Tracer=newD("Line",{Thickness=1.4,Visible=false}),TOut=newD("Line",{Thickness=3.5,Transparency=0.3,Visible=false,Color=Color3.new(0,0,0)})} end
local function rem(p) if cache[p] then for _,d in pairs(cache[p]) do pcall(function() d:Remove() end) end cache[p]=nil end end
for _,p in ipairs(Players:GetPlayers()) do add(p) end
Players.PlayerAdded:Connect(add); Players.PlayerRemoving:Connect(rem)
RS.RenderStepped:Connect(function()
    local bot=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y)
    for plr,d in pairs(cache) do
        local char=plr.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); local hum=char and char:FindFirstChildOfClass("Humanoid"); local head=char and char:FindFirstChild("Head")
        local hide=true
        if getgenv().Entrenched.ESP and hrp and hum and head and hum.Health>0 then
            if getgenv().Entrenched.TeamCheck and plr.Team==LP.Team then hide=true else
                local pos,on=Cam:WorldToViewportPoint(hrp.Position)
                if on then
                    local top=Cam:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0)); local bottom=Cam:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
                    local h=bottom.Y-top.Y; local w=h*0.62
                    if h>1 then hide=false -- INFINITE DISTANCE
                        local x,y=top.X-w/2, top.Y
                        local col=plr.Team==LP.Team and Color3.fromRGB(90,140,255) or Color3.fromRGB(255,60,60)
                        if getgenv().Entrenched.Boxes then d.Box.Visible=true; d.Fill.Visible=true; d.Box.Position=Vector2.new(x,y); d.Box.Size=Vector2.new(w,h); d.Box.Color=col; d.Fill.Position=Vector2.new(x,y); d.Fill.Size=Vector2.new(w,h); d.Fill.Color=col else d.Box.Visible=false; d.Fill.Visible=false end
                        if getgenv().Entrenched.Tracers then d.TOut.Visible=true; d.TOut.From=bot; d.TOut.To=Vector2.new(pos.X,y+h); d.Tracer.Visible=true; d.Tracer.From=bot; d.Tracer.To=Vector2.new(pos.X,y+h); d.Tracer.Color=col else d.Tracer.Visible=false; d.TOut.Visible=false end
                        d.Name.Visible=getgenv().Entrenched.Names; d.Name.Position=Vector2.new(pos.X,y-14); d.Name.Text=plr.Name; d.Name.Color=Color3.new(1,1,1)
                        if getgenv().Entrenched.Health then local pct=math.clamp(hum.Health/hum.MaxHealth,0,1); local bx=x-6; d.HPBg.Visible=true; d.HPBg.From=Vector2.new(bx,y); d.HPBg.To=Vector2.new(bx,y+h); d.HP.Visible=true; d.HP.From=Vector2.new(bx,y+h); d.HP.To=Vector2.new(bx,y+h - h*pct); d.HP.Color=Color3.fromHSV(pct*0.33,1,1) else d.HP.Visible=false; d.HPBg.Visible=false end
                    end
                end
            end
        end
        if hide then for _,v in pairs(d) do v.Visible=false end end
    end
end)

local gui=Instance.new("ScreenGui", gethui and gethui() or LP:WaitForChild("PlayerGui"))
gui.Name="Entrenched_Infinite_4080"; gui.ResetOnSpawn=false
local main=Instance.new("Frame",gui)
main.Size=UDim2.fromOffset(380,460); main.Position=UDim2.fromScale(0.5,0.5); main.AnchorPoint=Vector2.new(0.5,0.5)
main.BackgroundColor3=Color3.fromRGB(14,16,24); Instance.new("UICorner",main).CornerRadius=UDim.new(0,14)
local st=Instance.new("UIStroke",main) st.Color=Color3.fromRGB(70,90,160) st.Thickness=1.2
local title=Instance.new("TextLabel",main) title.Size=UDim2.new(1,-50,0,28); title.Position=UDim2.fromOffset(14,10); title.BackgroundTransparency=1; title.Text=" ENTRENCHED — INFINITE ESP  4080"; title.Font=Enum.Font.GothamBold; title.TextSize=13; title.TextColor3=Color3.fromRGB(220,225,255); title.TextXAlignment=Enum.TextXAlignment.Left
local close=Instance.new("TextButton",main) close.Size=UDim2.fromOffset(28,28); close.Position=UDim2.new(1,-32,0,8); close.Text="✕"; close.Font=Enum.Font.GothamBold; close.TextSize=14; close.TextColor3=Color3.fromRGB(230,230,230); close.BackgroundColor3=Color3.fromRGB(30,40,68); Instance.new("UICorner",close).CornerRadius=UDim.new(0,8); close.MouseButton1Click:Connect(function() getgenv().Entrenched.Aim=false; getgenv().Entrenched.ESP=false; for _,d in pairs(cache) do for _,v in pairs(d) do pcall(function() v:Remove() end) end end; fov:Remove(); gui:Destroy() end)
local list=Instance.new("Frame",main) list.Size=UDim2.new(1,-16,1,-48); list.Position=UDim2.fromOffset(8,38); list.BackgroundTransparency=1
local lay=Instance.new("UIListLayout",list) lay.Padding=UDim.new(0,6)
local function tog(name,key) local r=Instance.new("Frame",list) r.Size=UDim2.new(1,0,0,28); r.BackgroundColor3=Color3.fromRGB(22,28,44); Instance.new("UICorner",r).CornerRadius=UDim.new(0,8); local l=Instance.new("TextLabel",r) l.Size=UDim2.new(1,-70,1,0); l.Position=UDim2.fromOffset(10,0); l.BackgroundTransparency=1; l.Text=name; l.Font=Enum.Font.Gotham; l.TextSize=11; l.TextColor3=Color3.fromRGB(210,220,240); l.TextXAlignment=Enum.TextXAlignment.Left; local b=Instance.new("TextButton",r) b.Size=UDim2.fromOffset(52,22); b.Position=UDim2.new(1,-58,0.5,-11); b.Font=Enum.Font.GothamBold; b.TextSize=11; b.TextColor3=Color3.new(1,1,1); Instance.new("UICorner",b).CornerRadius=UDim.new(0,6); local function ref() b.Text=getgenv().Entrenched[key] and "ON" or "OFF"; b.BackgroundColor3=getgenv().Entrenched[key] and Color3.fromRGB(88,101,242) or Color3.fromRGB(50,60,85) end; ref(); b.MouseButton1Click:Connect(function() getgenv().Entrenched[key]=not getgenv().Entrenched[key]; ref() end) end
tog("Aimbot (Q)","Aim"); tog("Auto (no hold)","Auto"); tog("ESP (E)","ESP"); tog("Boxes","Boxes"); tog("Tracers","Tracers"); tog("Names","Names"); tog("Health","Health"); tog("Team Check","TeamCheck"); tog("Wall Check","WallCheck")
local note=Instance.new("TextLabel",list) note.Size=UDim2.new(1,0,0,18); note.BackgroundTransparency=1; note.Font=Enum.Font.Gotham; note.TextSize=9; note.TextColor3=Color3.fromRGB(120,130,150); note.Text="Infinite ESP + leaf ignore"
local dr,sp,so; main.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true; sp=i.Position; so=main.Position end end); main.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end); UIS.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-sp; main.Position=UDim2.new(so.X.Scale,so.X.Offset+d.X,so.Y.Scale,so.Y.Offset+d.Y) end end)
