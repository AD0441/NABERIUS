import AppKit
import NaberiusCore

struct TablePreviewLayout {
    let heights:[Double]
    let abbreviated:Bool
    let height:Double
    init(node:AcademicNode,width:Double,editing:Bool=false) {
        let columns=max(1,node.rows.first?.count ?? 1)
        let cellWidth=max(18,width/Double(columns)-14)
        heights=node.rows.prefix(8).map {row in
            min(90,max(29,row.map {value in
                ceil((value as NSString).boundingRect(with:NSSize(width:cellWidth,height:2000),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:[.font:DocumentFonts.font(size:12)]).height)+12
            }.max() ?? 29))
        }
        abbreviated=node.rows.count>8
        height=max(editing ? 300 : 0,heights.reduce(0,+)+(abbreviated ? 88 : 62))
    }
}
