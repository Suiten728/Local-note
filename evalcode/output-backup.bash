## evalコマンドを使用して、バックアップデータのjsonを読み込み再建を行う。

!eval
global json, io, discord
import json, io, discord
if not ctx.message.attachments: return await ctx.send("⚠️ `server_structure.json` ファイルを添付してください。")
data = json.loads((await ctx.message.attachments[0].read()).decode('utf-8'))
await ctx.send("🔄 【フェーズ1】既存チャンネルの削除を開始（このチャンネルは維持されます）...")
for c in guild.channels:
    if c.id != ctx.channel.id:
        try: await c.delete()
        except: pass
await ctx.send("🔄 【フェーズ2】既存ロールの削除と再作成を開始...")
role_mapping = {}
for r in guild.roles:
    if not r.is_default() and not r.managed:
        try: await r.delete()
        except: pass
for r_data in reversed(data.get("roles", [])):
    if r_data["managed"]: continue
    if r_data["position"] == 0:
        await guild.default_role.edit(permissions=discord.Permissions(r_data["permissions"]))
        role_mapping[str(r_data["id"])] = guild.default_role
        continue
    new_role = await guild.create_role(name=r_data["name"], permissions=discord.Permissions(r_data["permissions"]), color=discord.Color(r_data["color"]), hoist=r_data["hoist"], mentionable=r_data["mentionable"])
    role_mapping[str(r_data["id"])] = new_role
def build_ow(raw_ow):
    ow = {}
    for k, v in raw_ow.items():
        try:
            t_id = k.split('_')[-1]
            t = role_mapping.get(t_id) if k.startswith("role") else guild.get_member(int(t_id))
            if t: ow[t] = discord.PermissionOverwrite.from_pair(discord.Permissions(**{p: True for p in v.get("allow", [])}), discord.Permissions(**{p: True for p in v.get("deny", [])}))
        except: continue
    return ow
async def create_ch(ch_data, cat=None):
    ow = build_ow(ch_data.get("permission_overwrites", {}))
    t = ch_data["type"]
    n = ch_data["name"]
    pos = ch_data["position"]
    try:
        if t == "text" and hasattr(guild, "create_text_channel"): return await guild.create_text_channel(name=n, category=cat, overwrites=ow, position=pos, nsfw=ch_data.get("nsfw", False))
        if t == "news" and hasattr(guild, "create_text_channel"): return await guild.create_text_channel(name=n, category=cat, overwrites=ow, position=pos, nsfw=ch_data.get("nsfw", False), news=True)
        if t == "voice" and hasattr(guild, "create_voice_channel"): return await guild.create_voice_channel(name=n, category=cat, overwrites=ow, position=pos, nsfw=ch_data.get("nsfw", False))
        if t == "forum" and hasattr(guild, "create_forum_channel"): return await guild.create_forum_channel(name=n, category=cat, overwrites=ow, position=pos, topic=ch_data.get("topic", ""))
        if t == "forum": return await guild.create_text_channel(name=f"📝-{n}", category=cat, overwrites=ow, position=pos, nsfw=ch_data.get("nsfw", False))
    except:
        try: return await guild.create_text_channel(name=n, category=cat, overwrites=ow, position=pos)
        except: return None
    return None
await ctx.send("🔄 【フェーズ3】チャンネルと権限オーバーライドの再構築を開始...")
for ch in data.get("channels_without_category", []): await create_ch(ch)
for cat in data.get("categories", []):
    try:
        cat_ow = build_ow(cat.get("permission_overwrites", {}))
        new_cat = await guild.create_category(name=cat["name"], overwrites=cat_ow, position=cat["position"])
        for ch in cat.get("channels", []): await create_ch(ch, cat=new_cat)
    except: pass
await ctx.send("🎉 ロール、権限、各種チャンネル（フォーラム・アナウンス含む）の復元がすべて完了しました！\n⚠️ 役割を終えたこのチャンネルは、必要に応じて手動で削除してください。")
