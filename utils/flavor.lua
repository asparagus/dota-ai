phrases = { "?", "ez" };
function TrashTalk()
    local npcBot = GetBot();
    local r = RandomInt(1, 2);
    npcBot:ActionImmediate_Chat( phrases[r], true );
end