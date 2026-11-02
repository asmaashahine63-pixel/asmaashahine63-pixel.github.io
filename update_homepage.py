"""Insert or replace the PAM project card in YOUR CURRENT index.html.
Usage: python update_homepage.py /path/to/index.html
The script modifies the file supplied and saves an .html.bak backup beside it.
Requires beautifulsoup4: pip install beautifulsoup4
"""
from pathlib import Path
from bs4 import BeautifulSoup
import sys
p=Path(sys.argv[1] if len(sys.argv)>1 else 'index.html')
if not p.exists(): raise SystemExit('Could not find '+str(p))
card='<article class="card"><div class="meta">DIGITAL COMMUNICATIONS · 2025</div><h3>Digital PAM Channel &amp; Matched Filter</h3><p>Designed a MATLAB/Simulink study of matched-filter detection over an AWGN channel, with transmitted signals and BER/SER curves for 2-PAM through 1024-PAM, plus comparisons against theory. Explore all 27 original result figures and technical commentary.</p><p><a class="more" href="projects/pam-matched-filter.html">Explore project →</a></p></article>'
soup=BeautifulSoup(p.read_text(encoding='utf-8'),'html.parser')
section=soup.find(id='projects')
if section is None: raise SystemExit('No projects section found; original file unchanged.')
grid=section.find('div',class_='grid')
if grid is None: raise SystemExit('No project grid found; original file unchanged.')
for item in grid.find_all('article'):
    if 'pam-matched-filter.html' in str(item) or 'Digital PAM Channel' in item.get_text(): item.decompose()
grid.append(BeautifulSoup(card,'html.parser'))
p.with_suffix('.html.bak').write_text(p.read_text(encoding='utf-8'),encoding='utf-8')
p.write_text(str(soup),encoding='utf-8')
print('Updated homepage: '+str(p))
