-- I link tra i file .md non funzionano dentro il PDF:
-- li sostituisco con il solo testo, così non restano link rotti.
function Link(el)
  if el.target:match('%.md') or el.target:match('^%.') or el.target:match('^#') then
    return el.content
  end
end
