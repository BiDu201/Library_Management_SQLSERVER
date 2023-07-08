CREATE DATABASE QLThuVien
Go
USE QLThuVien
GO

/*TẠO BẢNG*/

CREATE TABLE DOCGIA
(
	MaDocGia CHAR(10) PRIMARY KEY,
	HoTen NVARCHAR(30),
	GioiTinh NVARCHAR(5),
	NamSinh DATE,
	DiaChi NVARCHAR(100),
	SDT NCHAR(12)
)

CREATE TABLE QUYEN
(
	LoaiQuyen INT PRIMARY KEY,
	TenQuyen NVARCHAR(20) UNIQUE
)

CREATE TABLE ACCOUNT
(
	MaTK CHAR(10) PRIMARY KEY,
	TenDangNhap NCHAR(20) UNIQUE,
	LoaiQuyen INT,
	MatKhau NCHAR(20),
	CONSTRAINT FK_ACCOUNT_QUYEN FOREIGN KEY (LoaiQuyen) REFERENCES QUYEN(LoaiQuyen)
)

CREATE TABLE NhaCungCap
(
	mancc CHAR(10),
	tenncc NVARCHAR(50),
	dchincc NVARCHAR(50),
	dthoaincc CHAR(12),
	CONSTRAINT PK_NhaCC PRIMARY KEY (mancc)
)

CREATE TABLE NXB
(
	MaNXB CHAR(10) PRIMARY KEY,
	TenNXB NVARCHAR(50) NOT NULL UNIQUE
)

CREATE TABLE GIASACH
(
	MaGS CHAR(10) PRIMARY KEY,
	TenGS NVARCHAR(50) NOT NULL UNIQUE
)

CREATE TABLE THELOAI
(
	MaTL CHAR(10) PRIMARY KEY,
	TenTL NVARCHAR(50) NOT NULL UNIQUE
)

CREATE TABLE TACGIA
(
	MaTG CHAR(10) PRIMARY KEY,
	TenTG NVARCHAR(50) NOT NULL
)

CREATE TABLE PhieuNhap
(
	mapn CHAR(10),
	ngaynhap DATE DEFAULT GETDATE(),
	mancc CHAR(10),
	MaTK CHAR(10),
	tongtien MONEY DEFAULT 0,
	CONSTRAINT [PK_PhieuNhap] PRIMARY KEY (mapn),
	Constraint FK_PhieuNhap_NhaCC Foreign Key (mancc) References NhaCungCap(mancc),
	Constraint FK_PhieuNhap_Account Foreign Key (MaTK) References ACCOUNT(MaTK)
)

CREATE TABLE SACH
(
	MaSach CHAR(10) PRIMARY KEY,
	TenSach NVARCHAR(50) NOT NULL,
	MaNXB CHAR(10),
	MaTL CHAR(10),
	MaTG CHAR(10),
	MaGS CHAR(10),
	SoLuong INT DEFAULT 0,
	CONSTRAINT FK_SACH_NXB FOREIGN KEY (MaNXB) REFERENCES NXB(MaNXB),
    CONSTRAINT FK_SACH_THELOAI FOREIGN KEY (MaTL) REFERENCES THELOAI(MaTL),
	CONSTRAINT FK_SACH_TACGIA FOREIGN KEY (MaTG) REFERENCES TACGIA(MaTG),
	CONSTRAINT FK_SACH_GIASACH FOREIGN KEY (MaGS) REFERENCES GIASACH(MaGS)
)

CREATE TABLE CTPhieuNhap
(
	mapn CHAR(10),
	MaSach CHAR(10),
	soluong INT,
	gianhap DECIMAL (18, 2),
	thanhtien MONEY DEFAULT 0,
	Constraint PK_ChiTietPN Primary Key (mapn,MaSach),
	Constraint FK_CTPN_PhieuNhap Foreign Key (mapn) References PhieuNhap(mapn),
	Constraint FK_CTPN_SACH Foreign Key (MaSach) References SACH(MaSach)
)

CREATE TABLE PHIEUMUON
(
	MaPhieu CHAR(13) PRIMARY KEY,
	MaDocGia CHAR(10),
	TinhTrang nvarchar(15) DEFAULT N'Đang mượn',
	NgayMuon DATE DEFAULT GETDATE(),
	NgayPhaiTra DATE DEFAULT DATEADD(month, 3, GETDATE()), /*Ngày phải trả: cách ngày mượn 3 tháng */
	CONSTRAINT FK_PHIEUMUON_DOCGIA FOREIGN KEY (MaDocGia) REFERENCES DOCGIA(MaDocGia)
)

CREATE TABLE CTPHIEUMUON
(
	MaPhieu CHAR(13),
	MaSach CHAR(10),
	Soluong int,
	CONSTRAINT PK_CTPM PRIMARY KEY (MaPhieu,MaSach),
	CONSTRAINT FK_CTPHIEUMUON_PHIEUMUON FOREIGN KEY (MaPhieu) REFERENCES PHIEUMUON(MaPhieu),
	CONSTRAINT FK_CTPHIEUMUON_SACH FOREIGN KEY (MaSach) REFERENCES SACH(MaSach)
)

CREATE TABLE PHIEUTRA
(
	MaPhieu CHAR(13) PRIMARY KEY,
	NgayTra DATE DEFAULT GETDATE(),
	GhiChu NVARCHAR(50),
	CONSTRAINT FK_PHIEUTRA_PHIEUMUON FOREIGN KEY (MaPhieu) REFERENCES PHIEUMUON(MaPhieu)
)

CREATE TABLE VIPHAM
(
	MaDocGia CHAR(10) PRIMARY KEY,
	SoNgayTre INT,
	TienPhat MONEY,
	CONSTRAINT FK_VIPHAM_DOCGIA FOREIGN KEY (MaDocGia) REFERENCES DOCGIA(MaDocGia)
)

/*---------------------------------------------------------------TRIGGER--------------------------------------------------------------------------*/

/*Viết trigger kiểm tra khi thêm hay sửa dữ liệu trên bảng PHIEUMUON thì ngày phải trả >= ngày mượn*/
Go
Create Trigger PhieuMuon_NgMuon_NgPTra on PHIEUMUON
For Insert, Update
As
	If(Select DATEDIFF(day,NgayMuon,NgayPhaiTra) From inserted) < 0
		Begin
			Print N'Ngày phải trả phải lớn hơn hoặc bằng ngày mượn'
			Rollback tran
		End
Go
/*Viết trigger kiểm tra khi thêm hay sửa dữ liệu trên bảng PHIEUTRA thì ngày trả >= ngày mượn*/
Create Trigger PhieuTra_NgMuon_NgTra on PHIEUTRA
For Insert, Update
As
	If(Select DATEDIFF(day,NgayMuon,NgayTra) From inserted,PHIEUMUON where inserted.MaPhieu = PHIEUMUON.MaPhieu) < 0
		Begin
			Print N'Ngày trả phải lớn hơn hoặc bằng ngày mượn'
			Rollback tran
		End
Go
/*Viết trigger kiểm tra giới tính của độc giả phải là ‘Nam’ hay ‘Nu’*/
Create Trigger KT_Phai On DocGia
For Insert, Update
As
	If(Select GioiTinh From inserted) not in (N'Nam',N'Nữ')
		begin
			print N'GIới tính phải là Nam hoặc Nữ'
			Rollback tran
		end
Go
/*Viết trigger kiểm tra tuổi của độc giả phải >=15*/
Create Trigger KT_Tuoi On DocGia
For Insert, Update
As
	if(Select (YEAR(GETDATE()) - YEAR(NamSinh)) From inserted) < 15
		begin
			print N'Tuổi phải lớn hơn hoặc bằng 15'
			Rollback tran
		end
Go
/*Trigger khi insert CTPhieuNhap*/
Create Trigger Trigger_Insert_CTPN on CTPhieuNhap
After Insert
As
	/*Tính thành tiền*/
	Update CTPhieuNhap
	Set thanhtien = (Select soluong*gianhap)

	/*Update lại soluong = 0 khi nó = null trong bảng SACH*/
	Update SACH
	Set SoLuong = 0
	Where SoLuong is NULL

	/*Update lại tongtien = 0 khi nó = null trong bảng PhieuNhap*/
	Update PhieuNhap
	Set tongtien = 0
	Where tongtien is NULL

	/*Update soluongton Sach bằng số lượng hiện tại cộng với số lượng vừa nhập vào CTPhieuNhap*/
	Update SACH
	Set SoLuong = SoLuong  + (Select soluong From inserted)
	Where SACH.MaSach = (Select MaSach From inserted)

	/*Update tongtien của mỗi phiếu nhập bằng tổng tiền hiện tại cộng với tiền vừa nhập vào CTPhieuNhap*/
	Update PhieuNhap
	Set tongtien = tongtien + (Select soluong*gianhap From inserted)
	Where PhieuNhap.mapn = (Select mapn from inserted)
Go
/*Trigger khi xóa CTPhieuNhap*/
Create Trigger Update_SLSP on CTPhieuNhap
For Delete
As
	/*Update lại soluongton = 0 khi nó = null */
	Update SACH
	Set SoLuong = 0
	Where SoLuong is NULL

	/*Update lại tongtien = 0 khi nó = null*/
	Update PhieuNhap
	Set tongtien = 0
	Where tongtien is NULL

	Update SACH
	Set SoLuong = SoLuong  - (Select soluong From deleted)
	Where SACH.MaSach = (Select MaSach From deleted)

	Update PhieuNhap
	Set tongtien = tongtien - (Select soluong*gianhap From deleted)
	Where PhieuNhap.mapn = (Select mapn from deleted)
Go

/*Cập nhật số lượng sách khi trả sách*/
/*Cursor và trigger*/
Create Trigger UpdateSLSach On PHIEUTRA
For Insert
As
	Declare CS_Sach Cursor
	For
		Select MaPhieu, Masach, Soluong From CTPHIEUMUON where MaPhieu = (Select MaPhieu From inserted)
	Open CS_Sach
	Declare @MaPhieu char(13), @MaSach char(10), @SoLuong int
	While 0=0
	Begin
		Fetch next from CS_Sach into @MaPhieu, @MaSach, @SoLuong
		If @@FETCH_STATUS <> 0 Break
		Update SACH
		Set SoLuong = SoLuong + @SoLuong
		Where MaSach = @MaSach
	End
	Close CS_Sach
	Deallocate CS_Sach
Go

/*----------------------------------------------------------------THÊM DỮ LIỆU--------------------------------------------------------------------------*/
SET DATEFORMAT DMY
Go
/*Nhập liệu bảng DOCGIA*/
INSERT INTO DOCGIA
VALUES('DG001',N'Đoàn Quang Minh',N'Nam','05/04/2002',N'Tân Phú','0339678501')
INSERT INTO DOCGIA
VALUES('DG002',N'Trương Cảnh Trường',N'Nam','25/01/2002',N'Tân Phú','0379201223')
INSERT INTO DOCGIA
VALUES('DG003',N'Bùi Nguyễn Duyên Anh',N'Nữ','03/02/2007',N'Quận 9','0339675001')
INSERT INTO DOCGIA
VALUES('DG004',N'Đặng Nguyễn Hoàng Yến Nhi',N'Nữ','05/07/2002',N'Dĩ An','0396541225')
INSERT INTO DOCGIA
VALUES('DG005',N'Lê Hùng Đức',N'Nam','01/10/2002',N'Thủ Đức','0937926613')
INSERT INTO DOCGIA
VALUES('DG006',N'Dương Khắc Hoàng',N'Nam','20/02/2002',N'Thủ Đức','0379195003')
INSERT INTO DOCGIA
VALUES('DG007',N'Thiều Thụy Thùy Trang',N'Nữ','12/06/2002',N'Quận 9','0963215670')

/*Nhập liệu bảng QUYEN*/
INSERT INTO QUYEN
VALUES(1,N'Quản trị viên'),
      (2,N'Thủ thư'),
	  (3,N'Đọc giả')

/*Nhập liệu bảng ACCOUNT*/
INSERT INTO ACCOUNT
VALUES('ADMIN','Admin',1,'123'),
      ('TT001','TBinh',2,'123'),
	  ('DG001','DocGia',3,'123')

/*Nhập liệu NhaCungCap*/
Insert Into NhaCungCap
Values('NCC001',N'Báo Pháp Luật_Bộ Tư Pháp',N'84/4 Trần Đình Xu, Q.1, TPHCM','8361402'),
      ('NCC002',N'Công ty phát hành sách Hà Nội',N'34 Tràng Tiền, Hà Nội','	9349480'),
	  ('NCC003',N'Cửa hàng CDROM',N'248 Tây Sơn, Hà Nội','8574660'),
	  ('NCC004',N'Nhà sách Nguyễn Huệ','40 Nguyễn Huệ, Q.1, TPHCM','9645821'),
	  ('NCC005',N'Nhà sách Sài Gòn',N'60-62 Lê Lợi, Q.1, TPHCM','3369871')

/*Nhập liệu NXB*/
INSERT INTO NXB
VALUES('NXB001',N'Thanh Niên'),
      ('NXB002',N'Hồng Đức'),
	  ('NXB003',N'Khoa Học Xã Hội'),
	  ('NXB004',N'Kim Đồng'),
	  ('NXB005',N'Trẻ')

/*Nhập liệu GIASACH*/
INSERT INTO GIASACH
VALUES('GS001',N'Công nghệ'),
      ('GS002',N'Kinh Tế'),
	  ('GS003',N'Thiếu nhi'),
	  ('GS004',N'Khoa học'),
	  ('GS005',N'Đại cương')

/*Nhập liệu THELOAI*/
INSERT INTO THELOAI
VALUES('TL001',N'Khoa học công nghệ - kinh tế'),
      ('TL002',N'Chính trị – pháp luật'),
	  ('TL003',N'Văn học nghệ thuật'),
	  ('TL004',N'Văn hóa xã hội – Lịch sử'),
	  ('TL005',N'Giáo trình'),
	  ('TL006',N'Truyện, tiểu thuyết'),
	  ('TL007',N'Tâm lý, tâm linh, tôn giáo'),
	  ('TL008',N'Thiếu nhi')

/*Nhập liệu TACGIA*/
INSERT INTO TACGIA
VALUES('TG001',N'Dương Hùng Văn'),
      ('TG002',N'Huỳnh Văn Ơn'),
	  ('TG003',N'Tạ Phi Hùng'),
	  ('TG004',N'Trần Huyền Trang'),
	  ('TG005',N'Xuân Đức')

/*Nhập liệu PhieuNhap*/
Insert Into PhieuNhap(mapn,mancc,MaTK)
Values('PN001','NCC001','TT001')
Insert Into PhieuNhap(mapn,mancc,MaTK)
Values('PN002','NCC002','TT001')
Insert Into PhieuNhap(mapn,mancc,MaTK)
Values('PN003','NCC003','TT001')
Insert Into PhieuNhap(mapn,mancc,MaTK)
Values('PN004','NCC001','TT001')

/*Nhập liệu bảng SACH*/
INSERT INTO SACH(MaSach,TenSach,MaNXB,MaTL,MaTG,MaGS)
VALUES('SH001',N'Lập trình hướng đối tượng OOP','NXB001','TL001','TG001','GS001')
INSERT INTO SACH(MaSach,TenSach,MaNXB,MaTL,MaTG,MaGS)
VALUES('SH002',N'Lập trình Web','NXB002','TL001','TG003','GS001')
INSERT INTO SACH(MaSach,TenSach,MaNXB,MaTL,MaTG,MaGS)
VALUES('SH003',N'Công nghệ phần mềm','NXB004','TL001','TG002','GS002')
INSERT INTO SACH(MaSach,TenSach,MaNXB,MaTL,MaTG,MaGS)
VALUES('SH004',N'Hệ thống thông tin','NXB005','TL001','TG004','GS003')
INSERT INTO SACH(MaSach,TenSach,MaNXB,MaTL,MaTG,MaGS)
VALUES('SH005',N'Cơ sở dữ liệu nâng cao','NXB002','TL004','TG001','GS005')
INSERT INTO SACH(MaSach,TenSach,MaNXB,MaTL,MaTG,MaGS)
VALUES('SH006',N'Thiết kế cơ sở dữ liệu','NXB004','TL002','TG003','GS002')
INSERT INTO SACH(MaSach,TenSach,MaNXB,MaTL,MaTG,MaGS)
VALUES('SH007',N'Hệ quản trị cơ sở dữ liệu','NXB002','TL002','TG003','GS004')
INSERT INTO SACH(MaSach,TenSach,MaNXB,MaTL,MaTG,MaGS)
VALUES('SH008',N'Quốc phòng & An ninh 1','NXB001','TL005','TG005','GS001')
INSERT INTO SACH(MaSach,TenSach,MaNXB,MaTL,MaTG,MaGS)
VALUES('SH009',N'Kinh tế chính trị Mac-Lenin','NXB001','TL002','TG005','GS001')
INSERT INTO SACH(MaSach,TenSach,MaNXB,MaTL,MaTG,MaGS)
VALUES('SH010',N'Tư tưởng Hồ Chí Minh','NXB005','TL004','TG002','GS003')

/*Nhập liệu bảng CTPhieuNhap*/
Insert Into CTPhieuNhap(mapn,MaSach,soluong,gianhap)
Values('PN001','SH001',100,25000)
Insert Into CTPhieuNhap(mapn,MaSach,soluong,gianhap)
Values('PN001','SH002',100,15000)
Insert Into CTPhieuNhap(mapn,MaSach,soluong,gianhap)
Values('PN002','SH003',100,10000)
Insert Into CTPhieuNhap(mapn,MaSach,soluong,gianhap)
Values('PN002','SH010',100,10000)
Insert Into CTPhieuNhap(mapn,MaSach,soluong,gianhap)
Values('PN003','SH004',100,12000)
Insert Into CTPhieuNhap(mapn,MaSach,soluong,gianhap)
Values('PN003','SH007',100,15000)
Insert Into CTPhieuNhap(mapn,MaSach,soluong,gianhap)
Values('PN004','SH008',100,12000)
Insert Into CTPhieuNhap(mapn,MaSach,soluong,gianhap)
Values('PN004','SH006',100,12000)

/*Nhập liệu bảng PHIEUMUON*/
--INSERT INTO PHIEUMUON(MaPhieu,MaDocGia)
--VALUES('PH001','DG001')
--INSERT INTO PHIEUMUON(MaPhieu,MaDocGia)
--VALUES('PH002','DG002')
--INSERT INTO PHIEUMUON(MaPhieu,MaDocGia)
--VALUES('PH003','DG003')
--INSERT INTO PHIEUMUON(MaPhieu,MaDocGia)
--VALUES('PH004','DG005')
--INSERT INTO PHIEUMUON(MaPhieu,MaDocGia)
--VALUES('PH005','DG006')
--INSERT INTO PHIEUMUON(MaPhieu,MaDocGia)
--VALUES('PH006','DG007')
--INSERT INTO PHIEUMUON(MaPhieu,MaDocGia)
--VALUES('PH007','DG001')
--INSERT INTO PHIEUMUON(MaPhieu,MaDocGia)
--VALUES('PH008','DG002')
--INSERT INTO PHIEUMUON(MaPhieu,MaDocGia)
--VALUES('PH009','DG003')
--INSERT INTO PHIEUMUON(MaPhieu,MaDocGia)
--VALUES('PH010','DG005')

/*Nhập bảng CTPHIEUMUON*/
--Insert Into CTPHIEUMUON
--Values('PH002','SH001',1)
--Insert Into CTPHIEUMUON
--Values('PH003','SH002',2)
--Insert Into CTPHIEUMUON
--Values('PH004','SH003',1)
--Insert Into CTPHIEUMUON
--Values('PH006','SH004',1)
--Insert Into CTPHIEUMUON
--Values('PH010','SH005',1)

/*Nhập bảng PHIEUTRA*/
--INSERT INTO PHIEUTRA(MaPhieu)
--VALUES('PH002')
--INSERT INTO PHIEUTRA(MaPhieu)
--VALUES('PH003')
--INSERT INTO PHIEUTRA(MaPhieu)
--VALUES('PH004')
--INSERT INTO PHIEUTRA(MaPhieu)
--VALUES('PH006')
--INSERT INTO PHIEUTRA(MaPhieu)
--VALUES('PH010')
 
 /*Truy vấn xuất tổng để thống kê trên Dashboard*/
--SELECT ISNULL(SUM(SoLuong),0) AS N'Số lượng đang có' FROM SACH
--SELECT ISNULL(COUNT(*),0) AS N'Số lượng đang có' FROM DOCGIA
--SELECT ISNULL(COUNT(*),0) AS N'Số lượng đang có' FROM PHIEUMUON
--SELECT ISNULL(COUNT(*),0) AS N'Số lượng đang có' FROM PHIEUTRA
--SELECT ISNULL(COUNT(*),0) AS N'Số lượng đang có' FROM VIPHAM

/*----------------------------------------------------------------Procedure---------------------------------------------------------------------------------*/

-------------------------------------------------------------------PhieuNhap và CTPhieuNhap------------------------------------------------------------------
Go
/*Show PhieuNhap*/
Create Proc Show_PN @mapn varchar(10)
As
	select * from PhieuNhap
	where CONCAT(mapn,ngaynhap) LIKE '%'+@mapn+'%'
Go

/*Thêm phiếu nhập*/
Create proc Insert_PN @mapn char(10), @mancc char(10), @matk char(10)
As
	INSERT INTO PhieuNhap(mapn,mancc,MaTK)
	VALUES(@mapn,@mancc,@matk)
Go

/*Thủ tục xóa 1 phiếu nhập*/
Create Proc Xoa_PN @mapn char(10)
As
	Delete From PhieuNhap Where mapn = @mapn
Go

/*Sửa phiếu nhập*/
--Set DATEFORMAT DMY
Create Proc Update_PN @mapn char(10), @ngaynhap date, @mancc char(10), @matk char(10)
As
	UPDATE PhieuNhap
	SET ngaynhap = @ngaynhap, mancc=@mancc, MaTK=@matk WHERE mapn = @mapn
Go

/*Show CTPhieuNhap*/
Create Proc Show_CTPN @mapn char(10)
As
	select * from CTPhieuNhap where mapn = @mapn
Go 

/*Thủ tục khi thêm dữ liệu vào CTPhieuNhap*/
Create Proc Insert_CTPhieuNhap @mapn char(10), @mash char(10), @sl int, @gianhap money
As
	Insert Into CTPhieuNhap(mapn,MaSach,soluong,gianhap)
	Values(@mapn,@mash,@sl,@gianhap)
Go

/*Xóa chi tiết phiếu nhập*/
Create proc Xoa_CTPN @mapn char(10), @mash char(10)
As
	Delete From CTPhieuNhap Where mapn = @mapn and MaSach = @mash
Go

-------------------------------------------------------------------PHIEUMUON và CTPHIEUMUON-----------------------------------------------------------------------------

/*Show borrow books*/
Create Proc ShowBorrows @maph char(13)
As
	If (Select MaDocGia from PHIEUMUON where MaPhieu LIKE @maph) is null
		SELECT DISTINCT ct.MaPhieu, ct.MaSach, TenSach, ct.SoLuong, NgayMuon, NgayPhaiTra, 'tendg' = NULL
		FROM PHIEUMUON pm, DOCGIA dg, SACH sh, CTPHIEUMUON ct
		Where pm.MaPhieu = ct.MaPhieu and ct.MaSach = sh.MaSach and ct.MaPhieu LIKE @maph
	Else
		SELECT ct.MaPhieu, ct.MaSach, TenSach, ct.SoLuong, NgayMuon, NgayPhaiTra, HoTen
		FROM PHIEUMUON pm, DOCGIA dg, SACH sh, CTPHIEUMUON ct
		Where pm.MaDocGia = dg.MaDocGia and pm.MaPhieu = ct.MaPhieu and ct.MaSach = sh.MaSach and ct.MaPhieu LIKE @maph
Go

/*Show những quyển sách có số lượng lớn hơn 0*/
Create Proc Show_Books @search nvarchar(30)
As
	SELECT MaSach,TenSach,TenNXB,TenTL,TenTG,TenGS
	FROM SACH sh, NXB nxb, THELOAI tl, TACGIA tg, GIASACH gs
	WHERE sh.MaNXB = nxb.MaNXB and sh.MaTL = tl.MaTL and sh.MaTG = tg.MaTG and sh.MaGS = gs.MaGS and CONCAT(TenSach,TenNXB,TenTL,TenTG,TenGS) LIKE N'%'+@search+'%' AND SoLuong >0
Go

/*Lấy ra mã phiếu gần nhất hay lớn nhất*/
Create Proc Top_MaPhieu @sdate varchar(15)
As
	SELECT TOP 1 MaPhieu
	FROM PHIEUMUON 
	WHERE MaPhieu LIKE ''+@sdate+'%'
	ORDER BY MaPhieu DESC
Go

/*Nhập CTPHIEUMUON*/
Create Proc Insert_CTPM @maph char(13), @mash char(10)
As
	INSERT INTO CTPHIEUMUON(MaPhieu, MaSach, SoLuong)
	VALUES(@maph,@mash,1)
Go

/*Nhập PHIEUMUON*/
Create Proc Insert_PM @maph char(13)
As
	INSERT INTO PHIEUMUON(MaPhieu)
	VALUES(@maph)
GO

/*Update số lượng sách mượn tăng thêm 1*/
Create Proc Update_SLTang @maph char(13), @mash char(10)
As
	UPDATE CTPHIEUMUON SET soluong = soluong + 1
	WHERE MaPhieu LIKE ''+@maph+'' and MaSach LIKE ''+@mash+''
Go
 
/*Update số lượng sách mượn giảm đi 1*/
Create Proc Update_SLGiam @maph char(13), @mash char(10)
As
	UPDATE CTPHIEUMUON SET soluong = soluong - 1
	WHERE MaPhieu LIKE ''+@maph+'' and MaSach LIKE ''+@mash+''
Go

/*Update số lượng trong bảng SACH khi trả sách*/
Create Proc Update_SLSACH @mash varchar(15), @sl int
As
	UPDATE SACH SET soluong = soluong - @sl WHERE MaSach LIKE @mash
Go

/*Xem Số lượng còn lại của mỗi quyển sách*/
Create Proc SLSach @mash varchar(15)
As
	SELECT SoLuong FROM SACH WHERE MaSach LIKE @mash
Go

/*Thủ tục cập nhật tình trạng trên PHIEUMUON và ghi chú trên PHIEUTRA*/
Create Proc Add_tt_gchu @mapn char(13)
As
	Insert Into PHIEUTRA(MaPHieu) VALUES(@mapn)

	Update PHIEUMUON
	Set TinhTrang = N'Đã trả'
	Where PHIEUMUON.MaPhieu = @mapn

	If(Select DATEDIFF(day,NgayPhaiTra,NgayTra) From PHIEUTRA pt,PHIEUMUON pm where pt.MaPhieu = pm.MaPhieu and pt.MaPhieu = @mapn) > 0
		Begin
			Update PHIEUTRA
			Set GhiChu = N'Trễ'
			Where MaPhieu = @mapn
		End
Go
----------------------------------------------------------------------VIPHAM-----------------------------------------------------------------------------
/*Tự động thêm khi đọc giả trả sách trễ hạn vào bảng VIPHAM*/
Create Proc Add_ViPham
As
	Delete From VIPHAM

	Insert Into VIPHAM(MaDocGia)
	Select MaDocGia
	From PHIEUMUON PM, PHIEUTRA PT
	Where PM.MaPhieu = PT.MaPhieu and DateDiff(day,NgayPhaiTra,NgayTra) > 0

	Update VIPHAM
	Set SoNgayTre = (Select Sum(DateDiff(day,NgayPhaiTra,NgayTra))
					 From PHIEUMUON PM, PHIEUTRA PT
					 Where PM.MaPhieu = PT.MaPhieu and DateDiff(day,NgayPhaiTra,NgayTra) > 0 and PM.MaDocGia = VIPHAM.MaDocGia
					 Group by MaDocGia)
	Update VIPHAM
	Set TienPhat = (Select SoNgayTre*1000)
Go

/*Xuất tên đăng nhập và tên quyền*/
Create Proc Show_ACCOUNT @tendn varchar(20), @mk varchar(20)
As
	SELECT TenDangNhap, TenQuyen
	FROM ACCOUNT acc, QUYEN q
	WHERE q.LoaiQuyen = acc.LoaiQuyen and TenDangNhap = @tendn and MatKhau = @mk
GO

/*Thủ tục thống kế sách mượn theo tháng, năm*/
--Create Proc ThongKe @thang int, @nam int
--As
--	Select dg.MaDocGia as N'Mã đọc giả', dg.HoTen as N'Họ tên', ct.MaSach as N'Mã sách', TenSach as N'Tên sách', ct.SoLuong, pm.NgayMuon
--	From PHIEUMUON pm, CTPHIEUMUON ct, SACH s, DOCGIA dg
--	Where pm.MaDocGia = dg.MaDocGia and ct.MaSach = s.MaSach and pm.MaPhieu = ct.MaPhieu and MONTH(NgayMuon)= @thang and YEAR(NgayMuon)= @nam
--Go

/*Trigger Kiểm tra số sách mượn không được quá 3*/
--Create Trigger KT_SachMuon on CTPHIEUMUON
--For Insert
--As
--	if(Select Count(*) From CTPHIEUMUON Where MaPhieu = (Select MaPhieu from inserted)) = 3
--		Begin
--			print N'Bạn chỉ được mượn tối đa 3 cuốn sách'
--			Rollback tran
--		End
--Go



/*Tìm kiếm thông tin khách hàng*/
Create proc Search_profile @TimKiem nvarchar(100)
As
	Select *
	From DOCGIA
	Where CONCAT(HoTen, DiaChi, SDT) LIKE '%'+@TimKiem+'%'
GO
/*Cập nhật thông tin khách hàng*/
Create proc Update_profile @MaDG char(10),  @HoTen nvarchar(50), @GioiTinh nvarchar(5),@NamSinh date, @DiaChi nvarchar(100), @SDT nchar(12)
As
	Update DOCGIA 
	Set HoTen =@HoTen, GioiTinh = @GioiTinh, NamSinh = @NamSinh, DiaChi = @DiaChi, SDT = @SDT
	Where MaDocGia = @MaDG

--Exec Update_profile 'DG001',N'123asdasdasd',N'Nam','05/04/2002',N'Tân Phú','0339678501'
GO
/*Thêm khách hàng*/
Create proc insert_cus @MaDG char(10),  @HoTen nvarchar(50), @GioiTinh nvarchar(5),@NamSinh date, @DiaChi nvarchar(100), @SDT nchar(12)
As
	Insert into DOCGIA (MaDocGia, HoTen, GioiTinh, NamSinh, DiaChi, SDT)
	Values(@MaDG, @HoTen, @GioiTinh, @NamSinh, @DiaChi, @SDT)

--Exec insert_cus 'DG0011',N'123123',N'Nam','05/04/2002',N'Tân Phú','0339678501'
GO
/*Xóa khách hàng*/
Create proc Delete_cus @MaDG char(10)
As
	Delete From DOCGIA 
	Where MaDocGia = @MaDG
GO


/*Tìm kiếm product*/
Create proc Search_product @TimKiem nvarchar(100)
As
	Select sh.MaSach,TenSach,TenNXB, TenTL, TenTG, TenGS, SoLuong 
	From SACH sh, NXB nxb, GIASACH gs, THELOAI tl, TACGIA tg 
	Where sh.MaNXB = nxb.MaNXB and sh.MaTL = tl.MaTL and sh.MaTG = tg.MaTG and sh.MaGS = gs.MaGS and CONCAT(TenSach, TenGS, TenTL, TenTG, TenNXB) LIKE N'%'+@TimKiem+'%'

--Exec Search_product N'Lập'
GO
/*Cập nhật product*/
Create proc Update_product @MaSH char(10), @TenSH nvarchar(50), @MaNXB char(10), @MaTL char(10), @MaTG char(10), @MaGS char(10), @SoLuong int
As
	Update SACH
	Set TenSach = @TenSH, MaNXB = @MaNXB, MaTL= @MaTL, MaTG = @MaTG, MaGS = @MaGS, SoLuong = @SoLuong
	Where MaSach = @MaSH

--Exec Update_product 'SH002',N'Ládasdasdab','NXB002','TL001','TG003','GS001',100
GO
/*Thêm product*/
Create proc Insert_product @MaSH char(10), @TenSH nvarchar(50), @MaNXB char(10), @MaTL char(10), @MaTG char(10), @MaGS char(10)
As
	Insert into SACH(MaSach, TenSach, MaNXB, MaTL, MaTG, MaGS)
	Values(@MaSH, @TenSH, @MaNXB, @MaTL, @MaTG, @MaGS)

--exec Insert_product 'SH0012',N'L12312asdfadf','NXB003','TL001','TG003','GS001'
GO
/*Xóa product*/
Create proc Delete_product @MaSH char(10)
As
	Delete From SACH
	Where MaSach = @MaSH
GO




/*Load user*/
Create proc Load_user @TimKiem nvarchar(100)
As
	SELECT MaTK, TenDangNhap, TenQuyen, MatKhau
	From ACCOUNT acc, QUYEN q
	Where acc.LoaiQuyen = q.LoaiQuyen and CONCAT(MaTK, TenDangNhap,TenQuyen) LIKE '%'+@TimKiem+'%'

--Exec Load_user 'TT001'
GO
/*Cập nhật user*/
Create proc Update_user @MaTK char(10), @TenDN nchar(20), @LoaiQ nchar(20), @MatKhau nchar(20)
As
	Update ACCOUNT
	Set TenDangNhap =@TenDN, LoaiQuyen = @LoaiQ, MatKhau = @MatKhau
	Where MaTK = @MaTK
--Exec Update_user 'DG002','MKhoa',3,'123'
GO
/*Thêm user*/
Create proc insert_user @MaTK char(10), @TenDN nchar(20), @LoaiQ nchar(20), @MatKhau nchar(20)
As
	Insert into ACCOUNT(MaTK, TenDangNhap, LoaiQuyen, MatKhau)
	Values (@MaTK, @TenDN, @LoaiQ, @MatKhau)

--Exec insert_user 'DG002','MKhoa',2,'123'
GO
/*Xóa user*/
Create proc Delete_user @MaTK char(10)
As
	Delete From ACCOUNT 
	Where MaTK = @MaTK
GO