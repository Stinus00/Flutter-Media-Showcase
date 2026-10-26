def convert_links(links):
    return [
        f"MediaLink(link:'{link}', type:'image', duration:60000.0),"
        for link in links
    ]


# Example list of URLs
links = [
    'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0270%20X1%3D477%20Y1%3D154%20X2%3D1847%20Y2%3D926.png',
'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0271%20X1%3D477%20Y1%3D154%20X2%3D1847%20Y2%3D926.png',
'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0272%20X1%3D73%20Y1%3D235%20X2%3D1443%20Y2%3D1007.png',
'https://s3.eu-central-003.backblazeb2.com/bcmdatabucket1/graphics/templateimages_n/0037/ftp_0273%20X1%3D477%20Y1%3D154%20X2%3D1847%20Y2%3D926.png',

]

print('\n--------------------\nLinks\n--------------------\n')
# Convert and print the results
for media_link in convert_links(links):
    print(media_link)
print('\n--------------------\nEnd\n--------------------\n')